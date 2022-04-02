// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Lighthouse is Ownable{

    struct Content {
        address user;
        string cid;
        string config;
        uint fileCost;
        string fileName;
        uint fileSize;
        uint timestamp;
    }

    struct Status {
        string dealIds;
        bool active;
    }

    event StorageRequest(address indexed uploader, string cid, string config, uint fileCost, string fileName, uint fileSize, uint timestamp);
    event BundleStorageRequest(address indexed uploader,Content[] contents,uint timestamp);
    event StorageStatusRequest(address requester, string cid);

    mapping(string => Status) public statuses; // address -> cid -> status

    function store(string calldata cid, string calldata config, string calldata fileName, uint fileSize)
        external
        payable
    {
        uint currentTime = block.timestamp;
        emit StorageRequest(msg.sender, cid, config, msg.value, fileName, fileSize, currentTime);
    }

    // For Bundle Storage Requests(Transactions) 
    // Paramater: content of the stored file i.e includes the address of the user 
    function bundleStore(Content[] memory contents)
        external
        payable
        onlyOwner 
    {
        emit BundleStorageRequest(msg.sender,contents,block.timestamp);
    }


    function getPaid(uint amount, address payable recipient)
        external
        onlyOwner
    {
        recipient.transfer(amount);
    }

    function requestStorageStatus(string calldata cid) 
        external
    {
        emit StorageStatusRequest(msg.sender, cid);
    }

    function publishStorageStatus(string calldata cid, string calldata dealIds, bool active) 
        external
        onlyOwner
    {   // restrict it to only to the owner address
        statuses[cid] = Status(dealIds, active);
    }

    fallback () external payable  {}

    receive() external payable { }
}