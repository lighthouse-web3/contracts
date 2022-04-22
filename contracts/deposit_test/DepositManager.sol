// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract DepositManager {
    using SafeMath for uint256;

    address public owner = msg.sender;
    address public manager = msg.sender;
    uint256 public costOfStorage = 5; // 5$/GB

    string[] public stableCoinsList;

    mapping(address => Deposit[]) public deposits;
    mapping(address => Storage) public storageList;
    mapping (string => address) public stableCoins;

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
  
    
    

    function addDeposit(string calldata  _coinSymbol) public payable {
        address wallet = msg.sender;

        require(IERC20(stableCoins[_coinSymbol]).balanceOf(wallet) > 0, "Must include deposit > 0");
        uint256 storagePurchased = (IERC20(stableCoins[_coinSymbol]).balanceOf(wallet)).div(costOfStorage);
 
        deposits[msg.sender].push(Deposit(block.timestamp, msg.value, storagePurchased));

        updateAvailableStorage(msg.sender, storagePurchased);

        emit AddDeposit(msg.sender, msg.value, storagePurchased);

        // top up storage against the deposit - above event emitted can be used in node
    }

    function changeCostOfStorage(uint256 newCost) public onlyOwner {
        costOfStorage = newCost;
    }

  

    function compareStrings(string memory a, string memory b) public view returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }


    function transferAmount(
        string memory _coinSymbol, 
        address wallet, 
        uint256 amount
    ) external onlyOwner {

        for(uint256 i=0 ; i < stableCoinsList.length; i++ ) {
            string memory coin= stableCoinsList[i];
            if(compareStrings(coin, _coinSymbol)) {
                require(amount <= IERC20(stableCoins[_coinSymbol]).balanceOf(address(this)));
                IERC20(stableCoins[_coinSymbol]).transfer(wallet, amount);
            }
        }

    }

    // adding and removing available stablecoins on the contract.

    function addCoin(
        string calldata _coinSymbol, 
        address _coinAddress
    ) external onlyOwner {
        require(stableCoins[_coinSymbol] == address(0), "Coin Already Added");
        stableCoinsList.push(_coinSymbol);
        stableCoins[_coinSymbol] = _coinAddress;
    } 


    function removeCoin(string calldata _coinSymbol)external onlyOwner {
        require(stableCoins[_coinSymbol] != address(0), "Coin Already Removed or doesn't exist");
        stableCoins[_coinSymbol] = address(0);
    }


    // update storage 

    function updateStorage(
        address user,
        uint256 filesize,
        string calldata cid
    ) public ManagerorOwner {
        storageList[user].cids.push(cid);
        storageList[user].totalStored = storageList[user].totalStored.add(filesize);
        storageList[user].availableStorage = storageList[user].availableStorage.sub(filesize);
        
    }

    function updateAvailableStorage(
        address user,
        uint256 addOnStorage
    ) public ManagerorOwner {
        Storage memory storageUpdate;
        storageUpdate.availableStorage = storageList[user].availableStorage.add(addOnStorage);
        storageUpdate.totalStored = storageList[user].totalStored;
        storageList[user] = storageUpdate;
    }

    function changeOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function changeManager(address _manager)external ManagerorOwner {
        manager = _manager;
    }


    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier ManagerorOwner() {
        require((msg.sender == manager) || (msg.sender == owner), "Not Authorised!!!");
        _;
    }

    
}
