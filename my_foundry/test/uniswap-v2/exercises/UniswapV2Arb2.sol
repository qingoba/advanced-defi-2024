// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IUniswapV2Pair} from
    "../../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";

contract UniswapV2Arb2 {
    struct FlashSwapData {
        // Caller of flashSwap (msg.sender inside flashSwap)
        address caller;
        // Pair to flash swap from
        address pair0;
        // Pair to swap from
        address pair1;
        // True if flash swap is token0 in and token1 out
        bool isZeroForOne;
        // Amount in to repay flash swap
        uint256 amountIn;
        // Amount to borrow from flash swap
        uint256 amountOut;
        // Revert if profit is less than this minimum
        uint256 minProfit;
    }

    // Exercise 1
    // - Flash swap to borrow tokenOut
    /**
     * @param pair0 Pair contract to flash swap
     * @param pair1 Pair contract to swap
     * @param isZeroForOne True if flash swap is token0 in and token1 out
     * @param amountIn Amount in to repay flash swap
     * @param minProfit Minimum profit that this arbitrage must make
     */
    function flashSwap(
        address pair0,
        address pair1,
        bool isZeroForOne,
        uint256 amountIn,
        uint256 minProfit
    ) external {
        // Write your code here
        // Don’t change any other code
        // Hint - use getAmountOut to calculate amountOut to borrow

        // (0) 首先需要明确这个练习的是从第一个合约借出一种代币 (比如 ETH), 最后归还另一种代币 (比如 DAI)
        //     所以 isZeroForOne == true 的含义是, 借出 token1, 归还 token0. 这就很有意思了

        // (1) 比较难的是, 如何计算应该归还的代币数量, 因为手续费不好计算
        //     测试用例已经帮我们计算好了, 我们应该归还的数量就是 amountIn, 那么就能用 getAmountOut 计算能借出的数量,
        //     这样做手续费是在 Pair 合约里计算的, 不用我们自己算.
        //     所以第一步就是计算应该借出的代币数量: 先获取储备量, 然后调用 getAmountOut 计算
        uint256 amountOut = 0;
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair0).getReserves();
        amountOut = getAmountOut({
            amountIn: amountIn,
            reserveIn: isZeroForOne ? reserve0 : reserve1,  // 传入 token0
            reserveOut: isZeroForOne ? reserve1 : reserve0  // 换出 token1
        });

        // (2) 调用 flashswap 并回调套利逻辑
        //     准备函数参数, 具体套利逻辑在回调函数内操作, 包括利润计算和转移
        FlashSwapData memory params = FlashSwapData({
            caller: msg.sender,
            pair0: pair0,
            pair1: pair1,
            isZeroForOne: isZeroForOne,
            amountIn: amountIn,
            amountOut: amountOut,
            minProfit: minProfit
        });
        bytes memory data = abi.encode(params);
        IUniswapV2Pair(pair0).swap({
            amount0Out: isZeroForOne ? 0 : amountOut,
            amount1Out: isZeroForOne ? amountOut : 0,
            to: address(this),          // 回调当前合约的 uniswapV2Call 函数
            data: data
        });

    }

    function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {
        // Write your code here
        // Don’t change any other code

        // (3) 解析参数, 执行 pair1 兑换
        //     由于我们直接使用 Pair 合约而不是 Router 合约进行交互, 因此要先转账, 从 pair0 从借出来的钱在当前合约中
        //     这里就涉及到一个很关键的问题了, 转账是如何进行的? 是 token 合约负责的转账.
        //     把借出的代币通过 ERC20 合约从当前合约转到 pair1 合约, token 的地址直接从 pair0 中取出来
        FlashSwapData memory params = abi.decode(data, (FlashSwapData));

        // (3.1) tokenOutPair0 是表示 flashswap 借出的代币地址
        //       tokenInPair0 表示 flashswap 应该归还的代币地址
        address tokenOutPair0;
        address tokenInPair0;
        if (params.isZeroForOne) {
            tokenOutPair0 = IUniswapV2Pair(params.pair0).token1();
            tokenInPair0 = IUniswapV2Pair(params.pair0).token0();
        } else {
            tokenOutPair0 = IUniswapV2Pair(params.pair0).token0();
            tokenInPair0 = IUniswapV2Pair(params.pair0).token1();
        }

        // (3.2) 将借出的代币转给 pair1 合约, 换出另一代币
        //       Pair 合约的 swap 函数并不计算能换出多少代币, 这个计算一般是在 Router 合约中的
        //       Pair 合约只检查符合手续费要求, 然后就把给定数量的代币转出, 并不管滑点之类的信息
        //       所以这里我们需要自己计算能够换出的数量, 然后将该数量传入 swap 函数, 要计算这个数量, 还要区分清楚 token0 和 token1
        //       
        //       我们转进去的代币是 tokenOutPair0, 需要知道 tokenOutPair0 在 pair1 里是 token0 还是 token1
        bool isToken0InPair1 = IUniswapV2Pair(params.pair1).token0() == tokenOutPair0;
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(params.pair1).getReserves();
        uint256 amountOutPair1 = getAmountOut({
            amountIn: params.amountOut,
            reserveIn: isToken0InPair1 ? reserve0 : reserve1,
            reserveOut: isToken0InPair1 ? reserve1 : reserve0
        });
        IERC20(tokenOutPair0).transfer(params.pair1, params.amountOut);
        IUniswapV2Pair(params.pair1).swap({
            amount0Out: isToken0InPair1 ? 0 : amountOutPair1,
            amount1Out: isToken0InPair1 ? amountOutPair1 : 0,
            to: address(this),
            data: ""
        });

        // (4) 非常值得注意的是, 从 pair1 中换出的代币数量就是 amoutOutPair1, 存在当前合约中
        //     根据 amountInPair0 计算利润, 最后把 amountInPair0 还给 pair0 合约, 剩下的返回给用户
        require(amountOutPair1 - params.amountIn >= params.minProfit, "profit is less than minProfit");
        IERC20(tokenInPair0).transfer(params.pair0, params.amountIn);
        IERC20(tokenInPair0).transfer(params.caller, amountOutPair1 - params.amountIn);
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
