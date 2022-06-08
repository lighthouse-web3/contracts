// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./Stargate/IStargateRouter.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Bridger is OwnableUpgradeable, UUPSUpgradeable {
    AggregatorV3Interface internal priceFeed;
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    uint8 public constant TYPE_SWAP_REMOTE = 1;

    mapping(address => uint256) public pids;

    address public stargateRouter;

    //handling Slippage
    uint256 slippageProtectionOut; //out of 10000. 50 = 0.5%
    uint256 constant DENOMINATOR = 10_000;

    event sgReceived(uint16 _chainId, bytes _srcAddress, address _token, uint256 amountLD);

    function initialize(
        address _stargateRouter,
        address[] memory tokens,
        uint256[] memory ids
    ) public initializer {
        require(tokens.length == ids.length && ids.length != 0);
        __Ownable_init();
        slippageProtectionOut = 2000;
        stargateRouter = _stargateRouter;
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        for (uint256 index = 0; index < ids.length; index++) {
            pids[tokens[index]] = ids[index];
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function getPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (uint256(price));
    }

    function getStorageCost(uint256 size) public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 _costOfStorage = 214748365;
        return size.mul(1 ether).mul(1e8).div(_costOfStorage.mul(uint256(price)));
    }

    function _changeStargateRouter(address _router) external onlyOwner {
        require(_router != address(0), "Must be validly address");
        stargateRouter = _router;
    }

    //can be used to add a new asset or change a current one
    function addAsset(address _address, uint256 _pid) external onlyOwner {
        pids[_address] = _pid;
    }

    //get the expected gas fee\
    function getSwapFee(uint16 _dstChainId) public view returns (uint256) {
        bytes memory _toAddress = abi.encodePacked(_msgSender());

        (uint256 nativeFee, ) = IStargateRouter(stargateRouter).quoteLayerZeroFee(
            _dstChainId,
            TYPE_SWAP_REMOTE,
            _toAddress,
            abi.encodePacked(),
            IStargateRouter.lzTxObj(0, 0, "0x")
        );

        return nativeFee;
    }

    function getMinOut(uint256 _amountIn) internal view returns (uint256) {
        return (_amountIn * (DENOMINATOR - slippageProtectionOut)) / DENOMINATOR;
    }

    //call the swap function to swap accorss chains
    function swap(
        uint16 chainId,
        address _asset,
        uint256 _amount,
        address _destinationComposer
    ) external payable onlyOwner returns (bool) {
        require(IERC20Upgradeable(_asset).allowance(_msgSender(), address(this)) >= _amount, "Allowance not adequate");

        uint256 pid = pids[_asset];
        require(pid != 0, "Asset Not Added");

        uint256 qty = _amount;
        uint256 amountOutMin = getMinOut(_amount);

        bytes memory _toAddress = abi.encode(_msgSender());
        bytes memory data = abi.encodePacked();

        require(msg.value >= getSwapFee(chainId), "Not enough funds for gas");

        IERC20Upgradeable(_asset).transferFrom(_msgSender(), address(this), _amount);
        IERC20Upgradeable(_asset).approve(stargateRouter, qty);
        IStargateRouter(stargateRouter).swap{ value: msg.value }(
            chainId, // send to Fuji (use LayerZero chainId)
            pid, // source pool id
            pid, // dest pool id
            payable(tx.origin), // refund adddress. extra gas (if any) is returned to this address
            qty, // quantity to swap
            amountOutMin, // the min qty you would accept on the destination
            IStargateRouter.lzTxObj(0, 0, "0x"), // 0 additional gasLimit increase, 0 airdrop, at 0x address
            _toAddress, // the address to send the tokens to on the destination
            data // bytes param, if you wish to send additional payload you can abi.encode() them here
        );

        return true;
    }

    /// @param _chainId The remote chainId sending the tokens
    /// @param _srcAddress The remote Bridge address
    /// @param _nonce The message ordering nonce
    /// @param _token The token contract on the local chain
    /// @param amountLD The qty of local _token contract tokens
    /// @param _payload The bytes containing the toAddress

    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes memory _payload
    ) external {
        require(msg.sender == address(stargateRouter), "only stargate router can call sgReceive!");
        address _toAddr = abi.decode(_payload, (address));
        IERC20Upgradeable(_token).transfer(_toAddr, amountLD);
        emit sgReceived(_chainId, _srcAddress, _token, amountLD);
    }

    /// @notice Sweep function in case any tokens get stuck in the contract
    /// @param _asset Address of the token to sweep
    function sweep(address _asset) external onlyOwner {
        IERC20Upgradeable(_asset).transfer(msg.sender, IERC20Upgradeable(_asset).balanceOf(address(this)));
    }

    receive() external payable {}
}
