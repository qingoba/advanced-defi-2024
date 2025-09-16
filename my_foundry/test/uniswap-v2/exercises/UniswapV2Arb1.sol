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
    }

    function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {
        // Write your code here
        // Don’t change any other code
    }
}
