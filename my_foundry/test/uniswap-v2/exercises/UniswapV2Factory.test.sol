// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../../../src/interfaces/IERC20.sol";
import {IWETH} from "../../../src/interfaces/IWETH.sol";
import {IUniswapV2Factory} from
    "../../../src/interfaces/uniswap-v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from
    "../../../src/interfaces/uniswap-v2/IUniswapV2Pair.sol";
import {
    DAI,
    WETH,
    UNISWAP_V2_PAIR_DAI_WETH,
    UNISWAP_V2_FACTORY
} from "../../../src/Constants.sol";
import {ERC20} from "../../../src/ERC20.sol";

contract UniswapV2FactoryTest is Test {
    IWETH private constant weth = IWETH(WETH);
    IUniswapV2Factory private constant factory =
        IUniswapV2Factory(UNISWAP_V2_FACTORY);

    function test_createPair() public {
        ERC20 token = new ERC20("test", "TEST", 18);

        // Exercise - deploy token + WETH pair contract
        // Write your code here
        // Don’t change any other code
        // 两个问题:
        // 1. 为什么可以对 token 进行 address 操作?
        //    在 Solidity 中, 每个合约都有一个地址. 变量 token 是一个合约实例,
        //    而 address(token) 将这个合约实例转换为其部署地址, 这是合法的操作,
        //    因为合约地址是合约的唯一标识。
        //
        // 2. 为什么存储 pair, token0, token1 的变量没有被声明为 memory?
        //    因为值类型的局部变量默认在栈上
        address pair = factory.createPair(address(token), WETH);
        // IUniswapV2Pair(pair).initialize(address(token), WETH);

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        if (address(token) < WETH) {
            assertEq(token0, address(token), "token 0");
            assertEq(token1, WETH, "token 1");
        } else {
            assertEq(token0, WETH, "token 0");
            assertEq(token1, address(token), "token 1");
        }
    }
}
