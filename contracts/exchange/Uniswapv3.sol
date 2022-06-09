// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IExchange.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract UniswapV3Exchange is OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    IUniswapRouter private uniswapRouterV3;
    address private WETH_native;
    uint256 minRefund = 1 ether;

    uint24[] private poolFees;

    function initialize(address _router, address _weth) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        uniswapRouterV3 = IUniswapRouter(_router);
        WETH_native = _weth;
        poolFees = new uint24[](3);
        poolFees[0] = 500; //slipage mode 0.05%
        poolFees[1] = 3000; //slipage mode 0.3%
        poolFees[2] = 10000; //slipage mode 1%
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @notice convertEthToExactStableCoin swaps a minimum possible amount of eth for a fixed amount of stableCoin.
    /// @dev The calling address send all the eth for this transaction
    /// @param amountOut The exact amount of stableCoin you want out
    /// @param tokenAddress tokenAddress
    /// @param feeType slipage index
    /// @param _to the account to send token too
    /// @param validFor how long this position should say open in secs
    /// @return amountIn The amount of ETH actually spent in the swap.
    function convertEthToExactStableCoin(
        uint256 amountOut,
        address tokenAddress,
        uint24 feeType,
        uint256 validFor,
        address _to
    ) external payable returns (uint256) {
        require(msg.value > 0, "Must pass non 0 ETH amount");

        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams(
            WETH_native,
            tokenAddress,
            poolFees[feeType],
            _to,
            block.timestamp + validFor,
            amountOut,
            msg.value,
            0
        );

        uint256 amountIn = uniswapRouterV3.exactOutputSingle{ value: msg.value }(params);
        uniswapRouterV3.refundETH();

        if (msg.value - amountIn > minRefund) {
            // refund leftover ETH to user
            (bool success, ) = msg.sender.call{ value: msg.value - amountIn }("");
            require(success);
        }
        return amountIn;
    }
}
