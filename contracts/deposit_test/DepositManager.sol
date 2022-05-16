// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DepositManager {
    using SafeMath for uint256;

    address private _owner;
    uint256 public costOfStorage = 5; // 5$/GB

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
        string[] cids;
        uint256 totalStored;
        uint256 availableStorage;
    }

    // Events
    event AddDepositEvent(
        address indexed depositor,
        address indexed coinAddress,
        uint256 amount,
        uint256 rate,
        uint256 storagePurchased
    );

    event whiteListingAddressEvent(
        address indexed whitelistAddress,
        bool indexed status
    );

    constructor() {
        _owner = msg.sender;
    }

    function addDeposit(address _coinAddress, uint256 _amount) external {
        address wallet = msg.sender;
        require(stableCoinRate[_coinAddress] != 0, "suggest coin to Admin");
        require(
            IERC20(_coinAddress).balanceOf(wallet) >= _amount,
            "insufficent Balance"
        );
        uint256 rate = (stableCoinRate[_coinAddress]).div(10**6).div(
            costOfStorage
        );
        uint256 storagePurchased = (IERC20(_coinAddress).balanceOf(wallet)).mul(
            rate
        );
        deposits[msg.sender].push(
            Deposit(block.timestamp, _amount, storagePurchased)
        );

        updateAvailableStorage(msg.sender, storagePurchased);

        IERC20(_coinAddress).transferFrom(wallet, address(this), _amount);
        emit AddDepositEvent(
            msg.sender,
            _coinAddress,
            _amount,
            rate,
            storagePurchased
        );

        // top up storage against the deposit - above event emitted can be used in node
    }

    function changeCostOfStorage(uint256 newCost) public onlyOwner {
        costOfStorage = newCost;
    }

    function getAvailableSpace(address _address) external view returns (uint256) {
        return storageList[_address].availableStorage;
    }

    function transferAmount(
        address _coinAddress,
        address wallet,
        uint256 amount
    ) external onlyOwner {
        require(amount <= IERC20(_coinAddress).balanceOf(address(this)));
        IERC20(_coinAddress).transfer(wallet, amount);
    }

    /**
     * @dev See
     *
     * whiteList an Address
     * Update SeedFund and Caller's Share
     * Note: rate is to 6 decimal place
     *  this implies if rate is set to
     *  1   is 1/10^6
     *  10^6  is 1
     */
    function addCoin(address _coinAddress, uint256 rate) external onlyOwner {
        require(_coinAddress != address(0), "Address can't be zero");
        require(rate != 0, "rate can't be zero");
        stableCoinRate[_coinAddress] = rate;
    }

    function removeCoin(address _coinAddress) external onlyOwner {
        require(_coinAddress != address(0), "Address can't be zero");
        require(stableCoinRate[_coinAddress] != 0, "coin already disabled");
        stableCoinRate[_coinAddress] = 0;
    }

    // update storage

    function updateStorage(
        address user,
        uint256 filesize,
        string calldata cid
    ) public ManagerorOwner {
        storageList[user].cids.push(cid);
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
        Storage memory storageUpdate;
        storageUpdate.availableStorage = storageList[user].availableStorage.add(
            addOnStorage
        );
        storageUpdate.totalStored = storageList[user].totalStored;
        storageList[user] = storageUpdate;
    }

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

    modifier ManagerorOwner() {
        if (msg.sender != owner()) {
            require(tx.origin != msg.sender, "Cant be called from User");
            require(whiteListedAddr[msg.sender], "Account Not Whitelisted");
        }
        _;
    }
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}
