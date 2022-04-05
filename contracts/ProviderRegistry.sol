// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.8 <0.8.0;

contract ProviderRegistry {
    address[] public providers;
    address public owner = msg.sender;

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    // Events
    event AddProvider(address indexed provider);
    event RemoveProvider(address indexed provider);

    // Methods
    function addProvider(address provider) public onlyOwner {
        providers.push(provider);
        emit AddProvider(provider);
    }

    function listProviders() public view returns (address[] memory) {
        address[] memory providersList = new address[](providers.length);
        for (uint256 i = 0; i < providers.length; i++) {
            providersList[i] = providers[i];
        }
        return providersList;
    }

    function removeProvider(address provider) public onlyOwner {
        uint256 index = 0;
        for (index = 0; index < providers.length; index++) {
            if (providers[index] == provider) {
                break;
            }
        }

        for (uint256 i = index; i < providers.length - 1; i++) {
            providers[i] = providers[i + 1];
        }
        providers.pop();
        emit RemoveProvider(provider);
    }
}
