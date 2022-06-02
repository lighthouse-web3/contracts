// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the Billing.sol
 */
interface IBilling {
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

    /**
     * @dev Emitted when a purchase is made
     *
     *
     * Note  account must a subscription
     */
    event Purchase(
        address indexed account,
        uint256 indexed subscriptionID,
        address indexed tokenAddress
    );

    /**
     * @dev Emitted blockNumber deduction duration is modified
     *
     *
     * Note  account must a subscription
     */
    event IncreaseBlockNumber(
        address indexed account,
        uint96 indexed subscriptionID,
        uint32 indexed increase
    );

    /**
     * @dev Emitted when contract is Updated
     *
     *
     * Note  account must a subscription
     */
    event UpdateContract(
        address indexed updateBy,
        address indexed subscriptionID
    );

    /**
     * @dev Emitted when a Subcription is cancelled
     *
     *
     * Note  account must a subscription
     */
    event SubscriptionStatus(
        address indexed account,
        bool active,
        uint64 indexed subscriptionID
    );

    /**
     * @dev Emitted when a Subcription is cancelled
     *
     *
     * Note  account must a subscription
     */
    event CancelSubscription(
        address indexed account,
        uint256 indexed subscriptionID
    );

    /**
     * @dev Emitted when a Subcription is cancelled
     *
     *
     * Note  account must a subscription
     */
    event StableCoinStatus(
        address indexed from,
        address indexed tokenAddress,
        uint64 rate,
        bool indexed isActive
    );
    

    function createSystemSubscription(SystemDefinedSubscription calldata _sub)
        external
        returns (uint64);

    function cancelSystemSubscription(uint64 id) external;
}
