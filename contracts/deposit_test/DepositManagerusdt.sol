// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../stablecoins/usdt.sol";

library _SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "_SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "_SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "_SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "_SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "_SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract DepositManager {
    using _SafeMath for uint256;
    address owner = msg.sender;
    uint256 public costOfStorage = 5; // 5$/GB
    usdt usdtToken;


    constructor(address _usdt){
        usdtToken = usdc(_usdt);
    }

    struct Deposit {
        uint256 timestamp;
        uint256 amount;
        uint256 storagePurchased;
    }

    struct Storage {
        string[] cids;
        uint256 totalStored;
        uint256 availableStorage;
    }

    mapping(address => Deposit[]) public deposits;
    mapping(address => Storage) public storageList;

    // Events
    event AddDeposit(
        address indexed depositor,
        uint256 amount,
        uint256 storagePurchased
    );
  
    // go through this ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
    // handle stablecoin payments
    

    function addDeposit() public payable {
        require(msg.value > 0, "Must include deposit > 0");
        uint256 storagePurchased = msg.value.div(costOfStorage); // @todo work on this part    -----// can lead to integer division.
        // ****************************************************************
        deposits[msg.sender].push(
            Deposit(block.timestamp, msg.value, storagePurchased)
        );

        ///*********************
        // update available storage
        updateAvailableStorage(msg.sender, storagePurchased);

        emit AddDeposit(msg.sender, msg.value, storagePurchased);

        // top up storage against the deposit - above event emitted can be used in node
    }

    function changeCostOfStorage(uint256 newCost) public onlyOwner {
        costOfStorage = newCost;
    }

    // create function for transfer onlyOwner()********

    function transferAmount(address wallet, uint256 amount) external onlyOwner{
        require( amount <= usdtToken.balanceOf(address(this)));
        usdtToken.transfer(wallet, amount);
    }




    // why not use the concept of whitelist addresses???? 
    // it can be onlyowner or the lighthouse contract.
    // test with msg.sender
    // create different function for bundle store (user)

    function updateStorage(
        address user,
        uint256 filesize,
        string calldata cid
    ) internal {
        storageList[user].cids.push(cid);
        storageList[user].totalStored = storageList[user].totalStored.add(filesize);
        storageList[user].availableStorage = storageList[user].availableStorage.sub(filesize);
        
    }

    function updateAvailableStorage(
        address user,
        uint256 addOnStorage
    ) internal {
        Storage memory storageUpdate;
        storageUpdate.availableStorage = storageList[user].availableStorage.add(addOnStorage);
        storageUpdate.totalStored = storageList[user].totalStored;
        storageList[user] = storageUpdate;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    
}
