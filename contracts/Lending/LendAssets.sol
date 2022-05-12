// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// AAVE
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";

contract LendAssets is Ownable {
    using SafeMath for uint256;

    event Deposit(
        address by,
        address indexed asset,
        address indexed from,
        uint256 amount,
        address indexed onBehalfOf,
        uint16 referralCode
    );

    event Withdraw(address indexed asset, uint256 amount, address indexed to);

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;
    IPool public immutable POOL;

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
        POOL = IPool(provider.getPool());
    }

    function supplyAsset(
        address asset,
        address from,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external onlyOwner {
        /// Transfer from wallet address
        IERC20(asset).transferFrom(from, address(this), amount);

        /// Approve LendingPool contract to move your DAI
        IERC20(asset).approve(address(POOL), amount);

        /// Deposit DAI
        POOL.supply(asset, amount, onBehalfOf, referralCode);

        emit Deposit(msg.sender, asset, from, amount, onBehalfOf, referralCode);
    }

    function withdrawAsset(
        address asset,
        address from,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external onlyOwner {
        /// Transfer from wallet address
        IERC20(asset).transferFrom(from, address(this), amount);

        /// Approve LendingPool contract to move your DAI
        IERC20(asset).approve(address(POOL), amount);

        /// Deposit DAI
        POOL.supply(asset, amount, onBehalfOf, referralCode);

        emit Withdraw(asset, amount, to);
    }

    function withdrawNative(address payable _to, uint256 amount)
        external
        onlyOwner
    {
        require(amount <= payable(address(this)).balance);
        _to.transfer(amount);
        emit Withdraw(asset, amount, to);
    }

    fallback() external payable {}

    receive() external payable {}
}
