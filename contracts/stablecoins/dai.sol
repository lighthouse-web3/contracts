pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol;

contract Dai{

    IERC20 public token;

    constructor(address _token){
        token= IERC20(_token);
    }
}