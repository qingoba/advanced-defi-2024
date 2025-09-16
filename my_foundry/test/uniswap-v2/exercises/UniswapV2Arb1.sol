// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IUniswapV2Pair} from
    "../../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from
    "../../../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";

contract UniswapV2Arb1 {
    struct SwapParams {
        // Router to execute first swap - tokenIn for tokenOut
        address router0;
        // Router to execute second swap - tokenOut for tokenIn
        address router1;
        // Token in of first swap
        address tokenIn;
        // Token out of first swap
        address tokenOut;
        // Amount in for the first swap
        uint256 amountIn;
        // Revert the arbitrage if profit is less than this minimum
        uint256 minProfit;
    }

    // Exercise 1
    // - Execute an arbitrage between router0 and router1
    // - Pull tokenIn from msg.sender
    // - Send amountIn + profit back to msg.sender
    function swap(SwapParams calldata params) external 
    {
        // Write your code here
        // Don’t change any other code

        // (1) 首先将用户的代币转入到当前合约中
        // IERC20(params.tokenIn).approve(msg.sender, params.amountIn);
        bool ret = IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn);
        require(ret, "transfer token from user failed");

        // (2) 调用 Router0 合约执行一次兑换, 换出的代币仍然存在当前合约里
        //     调用 swapExactTokensForTokens 需要指定 amoutOutMin, path 和 timestamp
        //     - amoutOutMin 用户设置滑点
        //     - path 指定兑换路径
        //     - timestamp 如何指定?
        IERC20(params.tokenIn).approve(params.router0, params.amountIn);
        address[] memory path = new address[](2);
        path[0] = params.tokenIn;
        path[1] = params.tokenOut;
        uint256[] memory amountOutArr = IUniswapV2Router02(params.router0).getAmountsOut(params.amountIn, path);
        uint256 amountOutNow = amountOutArr[1];
        uint256 amountOutMin = amountOutNow * 95 / 100;     // Solidity 没有小数
        uint256 amountOutReal = IUniswapV2Router02(params.router0).swapExactTokensForTokens(
            params.amountIn, amountOutMin, path, address(this), block.timestamp + 60)[1];
        
        // (3) 调用 Router1 合约执行另一次兑换, 换出的代币仍然存在当前合约里
        IERC20(params.tokenOut).approve(params.router1, amountOutReal);
        address[] memory path1 = new address[](2);
        path1[0] = params.tokenOut;
        path1[1] = params.tokenIn;
        uint256[] memory amountOutArr1 = IUniswapV2Router02(params.router1).getAmountsOut(amountOutReal, path1);
        uint256 amountOutNow1 = amountOutArr1[1];
        uint256 amountOutMin1 = amountOutNow1 * 95 / 100;
        uint256 amountOutReal1 = IUniswapV2Router02(params.router1).swapExactTokensForTokens(
            amountOutReal, amountOutMin1, path1, address(this), block.timestamp + 60)[1];
        
        // (4) 判断利润, 如果利润小于 minProfit, 则回滚交易
        require(amountOutReal1 - params.amountIn >= params.minProfit, "profit is less than minProfit");

        // (5) 将当前合约里的代币转回给用户
        ret = IERC20(params.tokenIn).transfer(msg.sender, amountOutReal1);
        require(ret, "transfer token to user failed");
    }

    // Exercise 2
    // - Execute an arbitrage between router0 and router1 using flash swap
    // - Borrow tokenIn with flash swap from pair
    // - Send profit back to msg.sender
    /**
     * @param pair Address of pair contract to flash swap and borrow tokenIn
     * @param isToken0 True if token to borrow is token0 of pair
     * @param params Swap parameters
     */
    function flashSwap(address pair, bool isToken0, SwapParams calldata params)
        external
    {
        // Write your code here
        // Don’t change any other code

        // (1) 携带大于零的 amount0Out 或 amount1Out, 以及合约地址, data, 去调用 swap
        //     swap 函数内部会回调当前合约的 uniswapV2Call 函数, 在 uniswapV2Call 函数中执行具体套利操作
        if (isToken0)
        {
            IUniswapV2Pair(pair).swap(params.amountIn, 0, address(this), abi.encode(params));

            // (7) 套利执行完毕, 将所有代币余额转给用户
            IERC20(params.tokenIn).transfer(msg.sender, IERC20(params.tokenIn).balanceOf(address(this)));
        }
        else
        {
            IUniswapV2Pair(pair).swap(0, params.amountIn, address(this), abi.encode(params));
            IERC20(params.tokenIn).transfer(msg.sender, IERC20(params.tokenIn).balanceOf(address(this)));
        }
        
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external 
    {
        // Write your code here
        // Don’t change any other code

        // (2) 此时该合约中已经借到了代币, 执行和第一个任务几乎一样的操作即可, 只不过钱的来源不一样
        //     需要先解码 data 中的数据
        (address router0, address router1, address tokenIn, address tokenOut, uint256 amountIn, uint256 minProfit) = 
            abi.decode(data, (address, address, address, address, uint256, uint256));
        
        // (3) 将借出的币转入第一个合约执行交换, 其实 amountBorrowed 就等于 amountIn
        uint256 amountBorrowed = amount0Out > 0 ? amount0Out : amount1Out;
        IERC20(tokenIn).approve(router0, amountBorrowed);
        
        // 第一次交换
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256 amountOutReal = IUniswapV2Router02(router0).swapExactTokensForTokens(
            amountIn, 0, path, address(this), block.timestamp + 60)[1];
        
        // 第二次交换
        IERC20(tokenOut).approve(router1, amountOutReal);
        address[] memory path1 = new address[](2);
        path1[0] = tokenOut;
        path1[1] = tokenIn;
        uint256 amountOutReal1 = IUniswapV2Router02(router1).swapExactTokensForTokens(
            amountOutReal, 0, path1, address(this), block.timestamp + 60)[1];
        
        // 计算还款金额和利润
        uint256 amountToRepay = amountBorrowed + (amountBorrowed * 3) / 997 + 1;
        IERC20(tokenIn).transfer(msg.sender, amountToRepay);    // msg.sender 就是 Uniswap Pair 合约

        // 判断利润
        require(amountOutReal1 - amountToRepay >= minProfit, "profit is less than minProfit");
    }
}
