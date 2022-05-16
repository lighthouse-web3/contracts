// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DepositManager {
    using SafeMath for uint256;

    /**
     * @dev Emitted when a Deposit is made
     *
     * Note that `value` may be zero.
     */
    event AddDepositEvent(
        address indexed depositor,
        address indexed coinAddress,
        uint256 amount,
        uint256 rate,
        uint256 storagePurchased
    );

    /**
     * @dev Emitted when an Address is whiteListed Or Unlisted
     *
     * Note that `value` may be zero.
     */
    event whiteListingAddressEvent(
        address indexed whitelistAddress,
        bool indexed status
    );

    address private _owner;
    uint256 private _costOfStorage = 214748365; // Byte per Dollar in these case 1gb/5$  which is eqivalent too ((1024**3) / 5)

    mapping(address => Deposit[]) public deposits;
    mapping(address => Storage) public storageList;
    mapping(address => bool) private whiteListedAddr;
    mapping(address => uint256) private stableCoinRate;

    struct Deposit {
        uint256 timestamp;
        uint256 amount;
        uint256 storagePurchased;
    }

    struct Storage {
        bytes32[] fileHashs;
        uint256 totalStored;
        uint256 availableStorage;
    }

    constructor() {
        _owner = msg.sender;
    }

    function addDeposit(address _coinAddress, uint256 _amount) external {
        address wallet = msg.sender;
        uint256 decimals = IERC20Metadata(_coinAddress).decimals();
        require(stableCoinRate[_coinAddress] != 0, "suggest coin to Admin");
        require(
            IERC20(_coinAddress).balanceOf(wallet) >= _amount,
            "insufficent Balance"
        );
        uint256 storagePurchased = _amount
            .mul(stableCoinRate[_coinAddress])
            .mul(costOfStorage())
            .div(10**decimals)
            .div(10**6);
        deposits[msg.sender].push(
            Deposit(block.timestamp, _amount, storagePurchased)
        );
        _updateAvailableStorage(msg.sender, storagePurchased);
        IERC20(_coinAddress).transferFrom(wallet, address(this), _amount);
        emit AddDepositEvent(
            msg.sender,
            _coinAddress,
            _amount,
            _costOfStorage,
            storagePurchased
        );
    }

    function changeCostOfStorage(uint256 newCost) public onlyOwner {
        _costOfStorage = newCost;
    }

    function getAvailableSpace(address _address)
        external
        view
        returns (uint256)
    {
        return storageList[_address].availableStorage;
    }

    /*
     * @dev
     * ApproveSpender designated Account
     */
    function approveSpender(
        address _coinAddress,
        address wallet,
        uint256 amount
    ) external onlyOwner {
        require(amount <= IERC20(_coinAddress).balanceOf(address(this)));
        IERC20(_coinAddress).approve(wallet, amount);
    }

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
    function addCoin(address _coinAddress, uint256 rate) external onlyOwner {
        require(_coinAddress != address(0), "Address can't be zero");
        require(rate != 0, "rate can't be zero");
        stableCoinRate[_coinAddress] = rate;
    }

    /*
     * @dev
     * ```Remove Coin```

     * Args:
     * coinAddress on the Network
     *
     *
     * Requirement:
     * - only callable by owner
     * - revert if the coinAddress rate is already set to zero
     *
     */
    function removeCoin(address _coinAddress) external onlyOwner {
        require(_coinAddress != address(0), "Address can't be zero");
        require(stableCoinRate[_coinAddress] != 0, "coin already disabled");
        stableCoinRate[_coinAddress] = 0;
    }

    /*
     *  @dev
     * ```Remove Coin```

     * Args:
     *  user Address
     *  fileSize
     *  file CID
     *
     *
     */

    function updateStorage(
        address user,
        uint256 filesize,
        bytes32 fileHash
    ) public ManagerorOwner {
        storageList[user].fileHashs.push(fileHash);
        storageList[user].totalStored = storageList[user].totalStored.add(
            filesize
        );
        storageList[user].availableStorage = storageList[user]
            .availableStorage
            .sub(filesize);
    }

    function updateAvailableStorage(address user, uint256 addOnStorage)
        public
        ManagerorOwner
    {
        _updateAvailableStorage(user, addOnStorage);
    }

    function _updateAvailableStorage(address user, uint256 addOnStorage)
        internal
    {
        Storage storage storagePointer = storageList[user];
        storagePointer.availableStorage = storagePointer.availableStorage.add(
            addOnStorage
        );
    }

    /**@dev transfer OwnerShip*/
    function changeOwner(address _newOwner) external onlyOwner {
        _owner = _newOwner;
    }

    function setWhiteListAddr(address _address, bool _status)
        external
        onlyOwner
    {
        whiteListedAddr[_address] = _status;
        emit whiteListingAddressEvent(_address, _status);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns costOfStorage
     */
    function costOfStorage() public view virtual returns (uint256) {
        return _costOfStorage;
    }

    /*
     * @dev
     * modifier```ManagerOrOwnerModify```
     *
     * Requirement:
     * - Reject direct calls by user
     */
    modifier ManagerorOwner() {
        require(
            whiteListedAddr[msg.sender] || msg.sender == owner(),
            "Account Not Whitelisted"
        );
        _;
    }

    /*
     * @dev
     * modifier```onlyOwner```
     *
     * Requirement:
     * - only callable by owner
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}
