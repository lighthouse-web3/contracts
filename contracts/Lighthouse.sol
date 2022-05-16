<<<<<<< HEAD
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract LighthouseV0 {
    address public owner = msg.sender;

    struct Content {
        string cid;
        string config;
        uint256 fileCost;
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
    event StorageStatusRequest(address requester, string cid);

    mapping(string => Status) public statuses; // address -> cid -> status

    function store(
        string calldata cid,
        string calldata config,
        string calldata fileName,
        uint256 fileSize
    ) external payable {
        uint256 currentTime = block.timestamp;
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

    function getPaid(uint256 amount, address payable recipient) external {
<<<<<<< HEAD
        require(msg.sender == owner, "only owner");
=======
        require(msg.sender == owner);
>>>>>>> 10b33d1 (formatting)
        recipient.transfer(amount);
    }

    function requestStorageStatus(string calldata cid) external {
        emit StorageStatusRequest(msg.sender, cid);
    }

    function publishStorageStatus(
        string calldata cid,
        string calldata dealIds,
        bool active
    ) external {
        // restrict it to only to the owner address
<<<<<<< HEAD
        require(msg.sender == owner, "only owner");
=======
        require(msg.sender == owner);
>>>>>>> 10b33d1 (formatting)
        statuses[cid] = Status(dealIds, active);
    }

    fallback() external payable {}
}
=======
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IDepositManager.sol";
import "@openzeppelin/contracts/utils/Context.sol"; // context file
import "@openzeppelin/contracts/access/Ownable.sol"; // ownable contract

contract Lighthouse is Ownable {
    IDepositManager public Deposit;
    uint256 bundleStoreID;

    constructor(address _deposit) {
        Deposit = IDepositManager(_deposit);
    }

    struct Content {
        address user;
        bytes32 fileHash;
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
        bytes32 fileHash,
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
    event StorageStatusRequest(address requester, bytes32 fileHash);

    mapping(bytes32 => Status) public statuses; // cid -> Status

    function store(
        bytes32 cid,
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
                    contents[i].fileHash
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

    function requestStorageStatus(bytes32 cid) external {
        emit StorageStatusRequest(msg.sender, cid);
    }

    function publishStorageStatus(
        bytes32 cid,
        string calldata dealIds,
        bool active
    ) external onlyOwner {
        // restrict it to only to the owner address
        statuses[cid] = Status(dealIds, active);
    }

    fallback() external payable {}

    receive() external payable {}
}
>>>>>>> 5ab3a74 (refactor: contracts)
