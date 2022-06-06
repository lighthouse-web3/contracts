// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IDepositManager.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract Lighthouse is OwnableUpgradeable , UUPSUpgradeable {

    IDepositManager public Deposit;
    uint256 bundleStoreID;

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
        uint256 indexed id,
        address indexed uploader,
        Content[] contents,
        bool didAllSuceed,
        uint256 timestamp
    );
    event BundleStorageResponse(
        uint256 indexed id,
        bool indexed isSuccess,
        uint256 count,
        Content[] contents,
        uint256 timestamp
    );
    event StorageStatusRequest(address requester, string cid);

    mapping(string => Status) public statuses; // cid -> Status

    function initialize(address _deposit) initializer public{
        __Ownable_init();
         Deposit = IDepositManager(_deposit);
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner{
    }

    function store(
        string calldata cid,
        string calldata config,
        string calldata fileName,
        uint256 fileSize
    ) external {
        uint256 currentTime = block.timestamp;
        Deposit.updateStorage(msg.sender, fileSize, cid);
        emit StorageRequest(
            msg.sender,
            cid,
            config,
            Deposit.costOfStorage() * fileSize,
            fileName,
            fileSize,
            currentTime
        );
    }

    // For Bundle Storage Requests(Transactions)
    // Paramater: content of the stored file i.e includes the address of the user
    function bundleStore(Content[] calldata contents) external onlyOwner {
        bundleStoreID += 1;
        Content[] memory failedUpload = new Content[](contents.length);
        uint256 failedCount = 0;
        for (uint256 i = 0; i < contents.length; i++) {
            if (
                Deposit.getAvailableSpace(contents[i].user) >=
                contents[i].fileSize
            ) {
                Deposit.updateStorage(
                    contents[i].user,
                    contents[i].fileSize,
                    contents[i].cid
                );
            } else {
                failedUpload[failedCount] = contents[i];
                failedCount += 1;
            }
        }

        emit BundleStorageRequest(
            bundleStoreID,
            msg.sender,
            contents,
            failedCount == 0,
            block.timestamp
        );
        if (failedCount != 0) {
            emit BundleStorageResponse(
                bundleStoreID,
                false,
                failedCount,
                failedUpload,
                block.timestamp
            );
        }
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
