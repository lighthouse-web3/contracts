// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract PriceAggregator {
    uint8 _decimal = 4;
    int256 _price = 18000000;

    function latestRoundData()
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (0, _price, 0, 0, 0);
    }

    function decimals() public view returns (uint8) {
        return _decimal;
    }
}
