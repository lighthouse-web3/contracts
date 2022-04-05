// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.8 <0.8.0;

contract Lighthouse {
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
        require(msg.sender == owner);
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
        require(msg.sender == owner);
        statuses[cid] = Status(dealIds, active);
    }

    fallback() external payable {}
}
