// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.8.0;

contract DepositManager {
    struct Deposit {
        uint timestamp;
        uint amount;
    }

    struct Storage {
        uint cids;
        uint totalStored;
        uint availableStorage;
    }

    mapping (address => Deposit[]) public deposits;
    mapping (address => Storage) public storageUsed;

    // Events
    event AddDeposit(
        address indexed depositor,
        uint256 amount
    );

    function addDeposit() public payable {
        require(msg.value > 0, "Must include deposit > 0");

        deposits[msg.sender].push(Deposit(block.timestamp, msg.value));
        emit AddDeposit(msg.sender, msg.value);

        // top up storage against the deposit - above event emitted can be used in node
    }

    
}
