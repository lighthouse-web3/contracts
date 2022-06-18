// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DepositManager is OwnableUpgradeable, UUPSUpgradeable {
    AggregatorV3Interface internal priceFeed;
    using SafeMath for uint256;

    /**
     * @dev Emitted when a withdraw approval is given
     *
     *
     * Note  account must a subscription
     */
    event withdrawApproval(address indexed account, address indexed tokenAddress, uint256 indexed amount);

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
    event whiteListingAddressEvent(address indexed whitelistAddress, bool indexed status);
    uint256 private _costOfStorage;
    uint256 public initalStorageSize;

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
        uint256 totalStored;
        uint256 availableStorage;
        bool isKnownUser;
        string[] fileHashs;
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _costOfStorage = 214748365; // Byte per Dollar in these case 1gb/5$  which is eqivalent too ((1024**3) / 5)
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function addDeposit(address _coinAddress, uint256 _amount) external {
        address wallet = msg.sender;
        uint256 decimals = IERC20Metadata(_coinAddress).decimals();
        require(stableCoinRate[_coinAddress] != 0, "suggest coin to Admin");
        require(IERC20(_coinAddress).balanceOf(wallet) >= _amount, "insufficent Balance");
        uint256 storagePurchased = _amount.mul(stableCoinRate[_coinAddress]).mul(costOfStorage()).div(10**decimals).div(
            10**6
        );
        deposits[msg.sender].push(Deposit(block.timestamp, _amount, storagePurchased));
        _updateAvailableStorage(msg.sender, storagePurchased);
        IERC20(_coinAddress).transferFrom(wallet, address(this), _amount);
        emit AddDepositEvent(msg.sender, _coinAddress, _amount, _costOfStorage, storagePurchased);
    }

    /** 
    * @dev the function set the storage Size new User will start with

    * @param _initalStorageSize value
    */
    function setInitalStorageSize(uint256 _initalStorageSize) public onlyOwner {
        initalStorageSize = _initalStorageSize;
    }

    /** 
    * @dev the function intializated the priceFeed Aggregator
    * see {chainlink for more}

    * @param aggregatorAddressFeed designated chainlink priceFeed address
    */
    function changePriceFeed(address aggregatorAddressFeed) public onlyOwner {
        priceFeed = AggregatorV3Interface(aggregatorAddressFeed);
    }

    /** 
    * @dev the function allows the owner to modify the cost of storage

    * @param newCost value to update cost to 
    */
    function changeCostOfStorage(uint256 newCost) public onlyOwner {
        _costOfStorage = newCost;
    }

    /** 
    * @dev this function calculates the cosr of storage in native eth
    * see {chainlink for more}

    * @param size the size of the file
    */
    function getStorageCost(uint256 size) public view returns (uint256) {
        require(address(priceFeed) != address(0), "price feed not set");
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return size.mul(1 ether).mul(10**priceFeed.decimals()).div(_costOfStorage.mul(uint256(price)));
    }

    /** 
    * @dev this function returns the available storage of a specified account/address

    * @param _address the address of the account you want to look up
    */
    function getAvailableSpace(address _address) external view returns (uint256) {
        return storageList[_address].availableStorage;
    }

    /**
     * @dev
     * Transfer balance to a designated Account
     */
    function transferAmount(
        address _coinAddress,
        address wallet,
        uint256 amount
    ) external onlyOwner {
        require(amount <= IERC20(_coinAddress).balanceOf(address(this)));
        IERC20(_coinAddress).transfer(wallet, amount);
        emit withdrawApproval(wallet, _coinAddress, amount);
    }

    /**
     * @dev
     * ```Add Coin```
     *  Set rate for coins

     * 
     * @param _coinAddress token address on the Network
     * @param rate a preset rate 
     *
     *
     * Requirement:
     * - only callable by owner
     * - rate can't be set to Zero
     *
     * Note: rate is to 6 decimal place
     *  this implies if rate is @ 0.992 per $
     *  rate should be set to 0.992*10^6 = 922000
     */
    function addCoin(address _coinAddress, uint256 rate) external onlyOwner {
        require(_coinAddress != address(0), "Address can't be zero");
        require(rate != 0, "rate can't be zero");
        stableCoinRate[_coinAddress] = rate;
    }

    /**
     * @dev
     * ```Remove Coin```

     * @param _coinAddress token on the Network
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

    /**
     *  @dev
     * ```Update Storage```

     *  @param user user Address
     *  @param filesize size of the file
     *  @param fileHash CID
     *
     */

    function updateStorage(
        address user,
        uint256 filesize,
        string calldata fileHash
    ) public ManagerorOwner {
        if (!storageList[user].isKnownUser) {
            _updateAvailableStorage(user, initalStorageSize);
            storageList[user].isKnownUser = true;
        }
        storageList[user].fileHashs.push(fileHash);
        storageList[user].totalStored = storageList[user].totalStored.add(filesize);
        storageList[user].availableStorage = storageList[user].availableStorage.sub(filesize);
    }

    /**
     *  @dev
     * ```instant Storage``` purchase storage on the go with nativeEth

     *  @param user user's Address
     *  @param filesize filesize
     *  @param fileHash CID
     *
     *
     */

    function instantStorage(
        address user,
        uint256 filesize,
        string calldata fileHash
    ) public payable {
        assert(msg.value >= getStorageCost(filesize));
        _updateAvailableStorage(user, filesize);
        updateStorage(user, filesize, fileHash);
    }

    /**
     * @dev this is an restricted function that increases the storage assigned to a user
     */
    function updateAvailableStorage(address user, uint256 addOnStorage) public ManagerorOwner {
        _updateAvailableStorage(user, addOnStorage);
    }

    /**
     * @dev this is an internal function that increases the storage assigned to a user
     */
    function _updateAvailableStorage(address user, uint256 addOnStorage) internal {
        Storage storage storagePointer = storageList[user];
        storagePointer.availableStorage = storagePointer.availableStorage.add(addOnStorage);
    }

    /**
     * @dev this function set the whitelisted status of an address and emits and event
     */
    function setWhiteListAddr(address _address, bool _status) external onlyOwner {
        whiteListedAddr[_address] = _status;
        emit whiteListingAddressEvent(_address, _status);
    }

    /**
     * @dev Returns costOfStorage
     */
    function costOfStorage() public view virtual returns (uint256) {
        return _costOfStorage;
    }

    /**
     * @dev
     * modifier```ManagerOrOwnerModify```
     *
     * Requirement:
     * - Reject direct from non whitelisted addresses
     */
    modifier ManagerorOwner() {
        require(whiteListedAddr[msg.sender] || msg.sender == owner(), "Account Not Whitelisted");
        _;
    }

    /// @dev this function allows the owner to transfer native ether
    /// to an address
    /// @param _amount Amount to claim
    /// @param _to the recipient Address
    function claimEth(address payable _to, uint256 _amount) external onlyOwner {
        assert(payable(address(this)).balance >= _amount);
        _to.transfer(_amount);
        emit withdrawApproval(_to, address(0), _amount);
    }

    receive() external payable {}
}
