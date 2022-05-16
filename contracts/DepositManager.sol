// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract DepositManager {
    address owner = msg.sender;
    uint256 public costOfStorage = 5; // 5$/GB

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
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
    address[] public whitelistedAddresses;

    mapping(address => bool) public checkWhiteListAdresses;
    mapping(address => Deposit[]) public deposits;
    mapping(address => Storage) public storageList;

    // Events
    event AddDeposit(
        address indexed depositor,
        uint256 amount,
        uint256 storagePurchased
    );

    function addDeposit() public payable {
        require(msg.value > 0, "Must include deposit > 0");
        uint256 storagePurchased = msg.value / costOfStorage; // @todo work on this part
        deposits[msg.sender].push(
            Deposit(block.timestamp, msg.value, storagePurchased)
        );
        emit AddDeposit(msg.sender, msg.value, storagePurchased);

        // top up storage against the deposit - above event emitted can be used in node
    }

    function updateStorage(
        address user,
        uint256 filesize,
        string calldata cid
    ) public {
        storageList[user].cids.push(cid);
        storageList[user].totalStored =
            storageList[user].totalStored +
            filesize;
        storageList[user].availableStorage =
            storageList[user].availableStorage -
            filesize;
    }

    function updateAvailableStorage(
        address user,
        uint256 _availableStorage,
        uint256 _totalStored
    ) public {
        Storage memory storageUpdate;
        storageUpdate.availableStorage = _availableStorage;
        storageUpdate.totalStored = _totalStored;
        storageList[user] = storageUpdate;
    }

    function changeCostOfStorage(uint256 newCost) public onlyOwner {
        costOfStorage = newCost;
    }
}
