pragma solidity ^0.6.0;

import "@sushiswap/core/contracts/uniswapv2/UniswapV2Router02.sol";

contract MockRouter is UniswapV2Router02 {
    constructor(address _factory, address _WETH) public UniswapV2Router02(_factory, _WETH) {}
}
