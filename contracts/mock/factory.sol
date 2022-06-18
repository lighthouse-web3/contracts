pragma solidity ^0.6.0;

import "@sushiswap/core/contracts/uniswapv2/UniswapV2Factory.sol";

contract MockFactory is UniswapV2Factory {
    constructor() public UniswapV2Factory(msg.sender) {}
}
