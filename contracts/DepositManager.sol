// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract DepositManager {
    address owner = msg.sender;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct Deposit {
        uint timestamp;
        uint amount;
        uint storagePurchased;
    }

    struct Storage {
        string[] cids;
        uint256 totalStored;
        uint256 availableStorage;
    }

    address[] public whitelistedAddresses;
 
    mapping (address => Deposit[]) public deposits;
    mapping (address => Storage) public storageUsed;

    // Events
    event AddDeposit(
        address indexed depositor,
        uint256 amount,
        uint256 storagePurchased
    );

    function addDeposit(uint _storagePurchased) public payable {
        require(msg.value > 0, "Must include deposit > 0");
        deposits[msg.sender].push(Deposit(block.timestamp, msg.value, _storagePurchased));
        emit AddDeposit(msg.sender, msg.value, _storagePurchased);

        // top up storage against the deposit - above event emitted can be used in node
    }

    function updateStorage(address user, uint256 filesize, string memory cid)
    public 
    whitelisted(msg.sender) 
    {
        Storage storage storageUpdate= storageUsed[user];
        storageUpdate[user].cids.push(cid);
        storageUpdate[user].totalStored = storageUpdate[user].totalStored + filesize;
        storageUpdate[user].availableStorage = storageUpdate[user].availableStorage - filesize;
    }

    function updateAvailableStorage(address user, uint256 _availableStorage)
    public 
    whitelisted(msg.sender)
    {
        Storage memory storageUpdate= Storage({
            cids:[],
            totalStored:0,
            availableStorage:_availableStorage
        });

        storageUsed[user] = storageUpdate;
    }

    function addWhitelistAddress(address addr) public onlyOwner {
        whitelistedAddresses.push(addr);
    }

    function removeWhitelistAddress(address addr) public onlyOwner {
        uint index = 0;
        for (index = 0; index < whitelistedAddresses.length; index++) {
            if (whitelistedAddresses[index] == addr) {
                break;
            }
        }

        for (uint i = index; i<whitelistedAddresses.length-1; i++){
            whitelistedAddresses[i] = whitelistedAddresses[i+1];
        }
        whitelistedAddresses.pop();
    }

    function listWhitelistAddresses() public view returns (address[] memory) {
        address[] memory addressList = new address[](whitelistedAddresses.length);
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            addressList[i] = whitelistedAddresses[i];
        }
        return addressList;
    }

    modifier whitelisted(address user){
        bool found= false;
        for(int i=0;i < whitelistedAddresses.length;i++) {
            if(whitelistedAddresses[i] == user) {
                found = true;
                break;
            }

        }

        require(found == true, "Address is not a whitelisted address");
        _;
    }
}
