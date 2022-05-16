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
  
    // go through this ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
    // handle stablecoin payments
    

    function addDeposit() public payable {
        require(msg.value > 0, "Must include deposit > 0");
        uint256 storagePurchased = msg.value / costOfStorage; // @todo work on this part    -----// can lead to integer division.
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
        storageList[user].totalStored =
            storageList[user].totalStored +
            filesize;
        storageList[user].availableStorage =
            storageList[user].availableStorage -
            filesize;
    }

    function updateAvailableStorage(
        address user,
        uint256 addOnStorage
    ) internal {
        Storage memory storageUpdate;
        storageUpdate.availableStorage = storageList[user].availableStorage + addOnStorage;
        storageUpdate.totalStored = storageList[user].totalStored;
        storageList[user] = storageUpdate;
    }

    
}
