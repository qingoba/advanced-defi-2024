// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {IWETH} from "../../src/interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../../src/interfaces/uniswap-v2/IUniswapV2Router02.sol";


// 这里导入的都是地址, 具体来说是以太坊上的合约地址
import {DAI, WETH, MKR, UNISWAP_V2_ROUTER_02} from "../../src/Constants.sol";

contract UniswapV2SwapAmountsTest is Test 
{
    // 这里并不是在调用构造函数, 而是做显式类型转换, 将 WETH 这个地址强转成一个接口
    // 之后就可以直接调用接口的函数 (相当于被实例化了一样)
    IWETH private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant mrk = IERC20(MKR);

    // 同样, 使用以太坊主网中 Uniswap V2 Router 合约的地址来实例一个接口
    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);

    function test_getAmountsOut() public view {
        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256 amountIn = 1e18;

        // 调用 Router 的 getAmountsOut, 不需要传入 factory
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);
    }

    function test_getAmountsIn() public view
    {
        // 调用的是 Router 合约中的 getAmountsIn, 其会进一步调用库函数的 getAmountsIn
        // 为了调用 getAmountsIn, 需要先看一下其函数签名, getAmountsIn(uint amountOut, address[] memory path) returns (uint[] memory amounts)

        // 目标是换取 0.01 个 MKR, 提供 1 个 WETH, 记得数量都要乘上 1e18
        // 由于 MRK/DAI 的 v2 池子非常浅, 所以这里不要填太大的数, 
        // 否则因为储备量不够, 为了计算 dy 能换出 dx 的数量, reserveOut - amountOut 时会出现减法不够减, 从而溢出 
        uint256 amountOut = 1e16;       

        address[] memory path = new address[](3);
        path[0] = WETH;
        path[1] = DAI;
        path[2] = MKR;

        uint256[] memory amounts = router.getAmountsIn(amountOut, path);

        console2.log("WETH", amounts[0]);
        console2.log("DAI", amounts[1]);
        console2.log("MKR", amounts[2]);
    }
}
