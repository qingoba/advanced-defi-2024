
## Exercise Test

我们在测试网上运行测试用例, 使用 alchemy 平台提供的 FROK_URL.

在 alchemy 上, FORK_URL 在 App 上提供, 目前使用的 App 链接https://dashboard.alchemy.com/apps/lz79ljf7pibyds2f/setup, 使用 Google 账号登陆

在构建之前, 先 `export FORK_URL=https://eth-mainnet.g.alchemy.com/v2/xCiveK4PE1ixtwHhQfZmy1NLIDRdVTRG`

构建并执行: `forge test --fork-url $FORK_URL --match-path test/uniswap-v2/exercises/UniswapV2Liquidity.test.sol`
