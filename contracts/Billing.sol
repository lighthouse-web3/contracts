// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./IBilling.sol";


contract Billing is IBilling, OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 constant RATE_DENOMINATOR = 1e6;
    SystemDefinedSubscription[] public contractSubscriptions;
    mapping(address => StableCoinState) public stableCoinStatus;
    mapping(address => UserSubscription) private userToSubscription;

    function initialize() public initializer {
        __Ownable_init();
    }

    //===============Admin Calls BEGIN=======================

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {
        emit UpdateContract(_msgSender(), newImplementation);
    }

    function createSystemSubscription(SystemDefinedSubscription calldata _sub)
        external
        virtual
        override
        onlyOwner
        returns (uint64)
    {
        contractSubscriptions.push(_sub);
        return uint64(contractSubscriptions.length);
    }

    function cancelSystemSubscription(uint64 subID)
        external
        virtual
        override
        onlyOwner
    {
        require(contractSubscriptions[subID].isActive != false);
        contractSubscriptions[subID].isActive = false;
    }

    function addStableCoin(
        address tokenAddress,
        StableCoinState calldata _stableCoin
    ) external onlyOwner {
        assert(tokenAddress != address(0));
        assert(stableCoinStatus[tokenAddress].rate == 0);
        stableCoinStatus[tokenAddress] = _stableCoin;
        emit StableCoinStatus(
            _msgSender(),
            tokenAddress,
            _stableCoin.rate,
            _stableCoin.isActive
        );
    }

    function increaseBlockNumber(uint96 subscriptionId, uint32 increase)
        external
        onlyOwner
    {
        assert(contractSubscriptions[subscriptionId].deductionIN > 0);
        contractSubscriptions[subscriptionId].deductionIN =
            contractSubscriptions[subscriptionId].deductionIN +
            increase;
        emit IncreaseBlockNumber(_msgSender(), subscriptionId, increase);
    }

    /// @param _asset Address of the token to claim
    /// @param _amount Amount to claim
    function claim(
        address _asset,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        assert(IERC20Upgradeable(_asset).balanceOf(address(this)) >= _amount);
        IERC20MetadataUpgradeable(_asset).approve(_to, _amount);
        emit withdrawApproval(_to, _asset, _amount);
    }

    receive() external payable {}

    //===============Admin Calls END=======================

    function getAmountToBeDeducted(address tokenAddress, uint64 subscriptionID)
        public
        view
        returns (uint256)
    {
        require(
            stableCoinStatus[tokenAddress].rate > 0,
            "TokenAddress Not Acceptable HERE"
        );
        return
            uint256(
                contractSubscriptions[subscriptionID].amount *
                    stableCoinStatus[tokenAddress].rate *
                    10**(IERC20MetadataUpgradeable(tokenAddress).decimals())
            ).div(RATE_DENOMINATOR * RATE_DENOMINATOR);
    }

    //============== User Calls Begin =================================
    function purchaseSubscription(address account) internal returns (bool) {
        UserSubscription storage subscription = userToSubscription[account];
        require(
            subscription.occuranceLeft > 0,
            "subscription expired or doesn't exist"
        );
        require(
            block.number - subscription.lastDebit >
                contractSubscriptions[subscription.systemDefinedSubscriptionID]
                    .frequencyOfDeduction
        );
        if (
            IERC20MetadataUpgradeable(subscription.tokenAddress).balanceOf(
                _msgSender()
            ) <
            getAmountToBeDeducted(
                subscription.tokenAddress,
                subscription.systemDefinedSubscriptionID
            )
        ) {
            return false;
        }
        IERC20Upgradeable(subscription.tokenAddress).transferFrom(
            account,
            address(this),
            getAmountToBeDeducted(
                subscription.tokenAddress,
                subscription.systemDefinedSubscriptionID
            )
        );
        subscription.occuranceLeft = subscription.occuranceLeft - 1;
        subscription.lastDebit = uint96(block.number);
        emit Purchase(
            account,
            subscription.systemDefinedSubscriptionID,
            subscription.tokenAddress
        );
        return true;
    }

    function activateSubscription(
        uint64 systemDefinedSubscriptionId,
        address tokenAddress
    ) external returns (bool) {
        assert(stableCoinStatus[tokenAddress].isActive == true);
        SystemDefinedSubscription storage subscription = contractSubscriptions[
            systemDefinedSubscriptionId
        ];
        require(subscription.isActive == true, "this offer has expired");
        assert(userToSubscription[_msgSender()].occuranceLeft == 0);
        uint256 amountTOBeDeducted = getAmountToBeDeducted(
            tokenAddress,
            systemDefinedSubscriptionId
        );
        require(
            IERC20MetadataUpgradeable(tokenAddress).allowance(
                _msgSender(),
                address(this)
            ) >= subscription.frequencyOfDeduction * amountTOBeDeducted,
            "Increase Allowance to match subscription"
        );
        userToSubscription[_msgSender()] = UserSubscription(
            subscription.frequencyOfDeduction,
            0,
            systemDefinedSubscriptionId,
            false,
            tokenAddress,
            uint96(block.number)
        );
        return purchaseSubscription(_msgSender());
    }

    function _isSubscriptionActive(address account)
        public
        returns (bool, uint64)
    {
        if (userToSubscription[_msgSender()].lastDebit == 0) {
            return (false, type(uint64).max);
        }
        if (
            block.number - userToSubscription[account].lastDebit <=
            contractSubscriptions[
                userToSubscription[account].systemDefinedSubscriptionID
            ].deductionIN
        ) {
            return (
                true,
                userToSubscription[account].systemDefinedSubscriptionID
            );
        } else {
            return (
                purchaseSubscription(account),
                userToSubscription[account].systemDefinedSubscriptionID
            );
        }
    }

    function isSubscriptionActive(address account) external {
        (bool status, uint64 id) = _isSubscriptionActive(account);
        emit SubscriptionStatus(account, status, id);
    }

    function cancelSubscription() external {
        require(
            userToSubscription[_msgSender()].occuranceLeft != 0,
            "No active subscription"
        );
        userToSubscription[_msgSender()].occuranceLeft = 0;
        userToSubscription[_msgSender()].isCancelled = true;
        IERC20Upgradeable(userToSubscription[_msgSender()].tokenAddress)
            .approve(address(this), 0);
        emit CancelSubscription(
            _msgSender(),
            userToSubscription[_msgSender()].systemDefinedSubscriptionID
        );
    }

    //============== User Calls ENDS =================================
}
