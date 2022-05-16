// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./deposit_test/DepositManager.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // context file
import "@openzeppelin/contracts/access/Ownable.sol"; // ownable contract


contract Lighthouse is Ownable {
    DepositManager public Deposit;

    constructor(address _deposit) {
        Deposit = DepositManager(_deposit);
    }

    struct Content {
        address user;
        string cid;
        string config;
        string fileName;
        uint256 fileSize;
        uint256 timestamp;
    }

    struct Status {
        string dealIds;
        bool active;
    }

    event StorageRequest(
        address indexed uploader,
        string cid,
        string config,
        uint256 fileCost,
        string fileName,
        uint256 fileSize,
        uint256 timestamp
    );
    event BundleStorageRequest(
        address indexed uploader,
        Content[] contents,
        uint256 timestamp
    );
    event StorageStatusRequest(address requester, string cid);

    mapping(string => Status) public statuses; // address -> cid -> status

    function store(
        string calldata cid,
        string calldata config,
        string calldata fileName,
        uint256 fileSize
    ) external payable {
        uint256 currentTime = block.timestamp;

        Deposit.updateStorage(msg.sender, fileSize, cid);
        emit StorageRequest(
            msg.sender,
            cid,
            config,
            msg.value,
            fileName,
            fileSize,
            currentTime
        );
    }

    // For Bundle Storage Requests(Transactions)
    // Paramater: content of the stored file i.e includes the address of the user
    function bundleStore(Content[] calldata contents)
        external
        payable
        onlyOwner
    {
        for (uint256 i = 0; i < contents.length; i++) {
            Deposit.updateStorage(
                contents[i].user,
                contents[i].fileSize,
                contents[i].cid
            );
        }

        emit BundleStorageRequest(msg.sender, contents, block.timestamp);
    }

    function getPaid(uint256 amount, address payable recipient)
        external
        onlyOwner
    {
        recipient.transfer(amount);
    }

    function requestStorageStatus(string calldata cid) external {
        emit StorageStatusRequest(msg.sender, cid);
    }

    function publishStorageStatus(
        string calldata cid,
        string calldata dealIds,
        bool active
    ) external onlyOwner {
        // restrict it to only to the owner address
        statuses[cid] = Status(dealIds, active);
    }

    fallback() external payable {}

    receive() external payable {}
}
