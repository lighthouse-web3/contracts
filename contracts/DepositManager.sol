// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract DepositManager {
    address public owner = msg.sender;

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
    mapping(address => Storage) public storageUsed;

    // Events
    event AddDeposit(
        address indexed depositor,
        uint256 amount,
        uint256 storagePurchased
    );

    function addDeposit(uint256 _storagePurchased) public payable {
        require(msg.value > 0, "Must include deposit > 0");
        deposits[msg.sender].push(
            Deposit(block.timestamp, msg.value, _storagePurchased)
        );
        emit AddDeposit(msg.sender, msg.value, _storagePurchased);

        // top up storage against the deposit - above event emitted can be used in node
    }

    function updateStorage(
        address user,
        uint256 filesize,
        string calldata cid
    ) public {
        storageUsed[user].cids.push(cid);
        storageUsed[user].totalStored =
            storageUsed[user].totalStored +
            filesize;
        storageUsed[user].availableStorage =
            storageUsed[user].availableStorage -
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
        storageUsed[user] = storageUpdate;
    }
}
