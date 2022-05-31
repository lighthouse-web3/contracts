// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract Billing is OwnableUpgradeable, UUPSUpgradeable {
    using SafeMathUpgradeable for uint256;
    struct SystemDefinedSubscription {
        uint32 frequencyOfDeduction; // the frequency of deduction
        uint32 deductionIN; // how long until the next deduction in Block Number
        uint128 amount; // the amount to the deducted in dollars * 1e6(RATE_DENOMINATOR)
        bool isActive; // can account still get this plan
        bytes7 code; // external unique ref or identify for example a 7 char string like FAM2021 or a byte ending of anything
    }
    struct UserSubscription {
        uint32 occuranceLeft;
        uint96 lastDebit;
        uint64 systemDefinedSubscriptionID;
        bool isCancelled;
        address tokenAddress;
        uint96 createdAt;
    }

    struct StableCoinState {
        uint64 rate;
        bool isActive;
    }

    uint32 constant RATE_DENOMINATOR = 100_000;
    SystemDefinedSubscription[] public contractSubscriptions;
    mapping(address => StableCoinState) private stableCoinStatus;
    mapping(address => UserSubscription) private userToSubscription;

    function initialize() public initializer {
        __Ownable_init();
    }

    //===============Admin Calls BEGIN=======================

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function createSubscription(SystemDefinedSubscription calldata _sub)
        external
        onlyOwner
        returns (uint64)
    {
        contractSubscriptions.push(_sub);
        return uint64(contractSubscriptions.length);
    }

    function addStableCoin(
        address tokenAddress,
        StableCoinState calldata _stableCoin
    ) external onlyOwner returns (bool) {
        require(tokenAddress != address(0));
        assert(stableCoinStatus[tokenAddress].rate == 0);
        stableCoinStatus[tokenAddress] = _stableCoin;
        return true;
    }

    function increaseBlockNumber(uint256 subscriptionId, uint32 increase)
        external
        onlyOwner
    {
        assert(contractSubscriptions[subscriptionId].deductionIN > 0);
        contractSubscriptions[subscriptionId].deductionIN =
            contractSubscriptions[subscriptionId].deductionIN +
            increase;
    }

    //===============Admin Calls END=======================

    function _getAmountToBeDeducted(address tokenAddress, uint64 subscriptionID)
        internal view
        returns (uint256)
    {
        return
            uint256(
                contractSubscriptions[subscriptionID].amount *
                    stableCoinStatus[tokenAddress].rate *
                    IERC20MetadataUpgradeable(tokenAddress).decimals()
            ).div(RATE_DENOMINATOR**2);
    }

    //============== User Calls Begin =================================
    function purchaseSubscription(address account) internal returns (bool) {
        UserSubscription storage subscription = userToSubscription[account];
        assert(subscription.lastDebit > 0);
        require(
            block.number - subscription.lastDebit >
                contractSubscriptions[subscription.systemDefinedSubscriptionID]
                    .frequencyOfDeduction
        );
        if (
            IERC20MetadataUpgradeable(subscription.tokenAddress).balanceOf(
                _msgSender()
            ) <
            _getAmountToBeDeducted(
                subscription.tokenAddress,
                subscription.systemDefinedSubscriptionID
            )
        ) {
            return false;
        }
        IERC20Upgradeable(subscription.tokenAddress).transferFrom(
            account,
            address(this),
            contractSubscriptions[subscription.systemDefinedSubscriptionID]
                .amount
        );
        subscription.lastDebit = subscription.lastDebit - 1;
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
        assert(userToSubscription[_msgSender()].occuranceLeft == 0);
        uint256 amountTOBeDeducted = _getAmountToBeDeducted(
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

    function isSubscriptionActive(address account)
        external
        returns (bool, uint96)
    {
        if (userToSubscription[_msgSender()].lastDebit == 0) {
            return (false, type(uint96).max);
        }
        if (
            block.number - userToSubscription[account].lastDebit <
            contractSubscriptions[
                userToSubscription[account].systemDefinedSubscriptionID
            ].frequencyOfDeduction
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

    function cancelSubscription() external {
        assert(userToSubscription[_msgSender()].occuranceLeft != 0);
        userToSubscription[_msgSender()].occuranceLeft = 0;
        userToSubscription[_msgSender()].isCancelled = true;
    }

    //============== User Calls ENDS =================================
}
