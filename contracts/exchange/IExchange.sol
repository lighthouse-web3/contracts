// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExchange {
    function convertEthToExactStableCoin(
        uint256 amountOut,
        address tokenAddress,
        uint24 feeType,
        uint256 validFor,
        address _to
    ) external payable;
}
