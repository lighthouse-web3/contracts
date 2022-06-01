// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the lighthouse.sol
 */
interface IDepositManager {
    /**
     * @dev Purchase Storage from with accepted stable coin
     */
    function addDeposit(address _coinAddress, uint256 _amount)
        external
        returns (bool);

    /**
     * @dev set Cost of Storagr
     */
    function changeCostOfStorage(uint256 newCost) external;

    /*
     * @dev Remove Coin from Allowed List
     *
     * Args:
     * coinAddress on the Network
     *
     *
     * Requirement:
     * - only callable by owner
     * - revert if the coinAddress rate is already set to zero
     *
     */
    function removeCoin(address _coinAddress) external;

    /*
     * @dev
     * ```Add Coin```
     *  Set rate for coins

     * Args:
     * coinAddress on the Network
     * Rate: kindly see Not below
     *
     *
     * Requirement:
     * - only callable by owner
     * - rate can't be set to Zero
     *
     * Note: rate is to 6 decimal place
     *  this implies if rate is @0.992 per $
     *  rate should be set to 0.992*10^6 = 922000
     */

    function addCoin(address _coinAddress, uint256 rate) external;

    /*
     * @dev
     * Change OwnerShip
     *
     */
    function changeOwner(address _newOwner) external;

    /**
     * @dev Returns the address of the current owner.
     */

    function setWhiteListAddr(address _address, bool _status) external;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address);

    /*
     *  @dev
     * ```Remove Coin```

     * Args:
     *  user Address
     *  fileSize
     *  file CID
     *
     */
    function updateStorage(
        address user,
        uint256 filesize,
        string calldata cid
    ) external;

    /*
     *  @dev getAvailable Storage

     * Args:
     *  _address: query user address
     *
     * Returns:
     * uint: Available Storage
     */
    function getAvailableSpace(address _address)
        external
        view
        returns (uint256);

    /*
     * @dev
     * Transfer balance to a designated Account
     */
    function transferAmount(
        address _coinAddress,
        address wallet,
        uint256 amount
    ) external;

    /*
    @dev get costOfStorage
    */
    function costOfStorage() external view returns (uint256);
}
