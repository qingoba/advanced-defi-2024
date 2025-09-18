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
