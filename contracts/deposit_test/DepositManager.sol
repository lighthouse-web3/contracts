// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract DepositManager {
    using SafeMath for uint256;

    address public owner = msg.sender;
    address public manager = msg.sender;
    uint256 public costOfStorage = 5; // 5$/GB

    string[] public stableCoins;

    mapping(address => Deposit[]) public deposits;
    mapping(address => Storage) public storageList;
    mapping (string => address) public stableCoin;

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
    event AddDeposit(
        address indexed depositor,
        uint256 amount,
        uint256 storagePurchased
    );
  
    // go through this ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`
    // handle stablecoin payments

    // ###################################
    // update according to three coins
    // mapping (symbol => addresses) function 
    // add manager 
    
    

    function addDeposit(string calldata  _coinSymbol) public payable {
        address wallet = msg.sender;

        require(IERC20(stableCoin[_coinSymbol]).balanceOf(wallet) > 0, "Must include deposit > 0");
        uint256 storagePurchased = (IERC20(stableCoin[_coinSymbol]).balanceOf(wallet)).div(costOfStorage); // @todo work on this part    -----// can lead to integer division.
        // ****************************************************************
        deposits[msg.sender].push(Deposit(block.timestamp, msg.value, storagePurchased));

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

    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }


    function transferAmount(string memory _coinSymbol, address wallet, uint256 amount) external onlyOwner{

        for(uint256 i=0;i < stableCoins.length; i++){
            string memory coin= stableCoins[i];
            if(compareStrings(coin, _coinSymbol)){
                require(amount <= IERC20(stableCoin[_coinSymbol]).balanceOf(address(this)));
                IERC20(stableCoin[_coinSymbol]).transfer(wallet,amount);
            }
        }

    }

    function addCoin(string calldata _coinSymbol, address _coinAddress) external onlyOwner{
        require(stableCoin[_coinSymbol] == address(0),"Coin Already Added");
        stableCoins.push(_coinSymbol);
        stableCoin[_coinSymbol] = _coinAddress;
    } 

    function removeCoin(string calldata _coinSymbol)external onlyOwner{
        require(stableCoin[_coinSymbol] != address(0), "Coin Already Removed or doesn't exist");
        stableCoin[_coinSymbol] = address(0);
    }




    // why not use the concept of whitelist addresses???? 
    // it can be onlyowner or the lighthouse contract.
    // test with msg.sender
    // create different function for bundle store (user)

    function updateStorage(
        address user,
        uint256 filesize,
        string calldata cid
    ) public onlyManager {
        storageList[user].cids.push(cid);
        storageList[user].totalStored = storageList[user].totalStored.add(filesize);
        storageList[user].availableStorage = storageList[user].availableStorage.sub(filesize);
        
    }

    function updateAvailableStorage(
        address user,
        uint256 addOnStorage
    ) public onlyManager {
        Storage memory storageUpdate;
        storageUpdate.availableStorage = storageList[user].availableStorage.add(addOnStorage);
        storageUpdate.totalStored = storageList[user].totalStored;
        storageList[user] = storageUpdate;
    }

    function changeOwner(address _owner) external onlyOwner{
        owner = _owner;
    }

    function changeManager(address _manager)external onlyManager{
        manager = _manager;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager(){
        require((msg.sender == manager) || (msg.sender == owner),"Not Authorised!!!");
        _;
    }

    
}
