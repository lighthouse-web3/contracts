// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router02.sol";
// import "@sushiswap/core/contracts/uniswapv2/libraries/UniswapV2Library.sol";
// import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
// import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IUniswap {
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function WETH() external pure returns (address);
}

contract SwapClient is OwnableUpgradeable, UUPSUpgradeable {
    IUniswap router;
    mapping(address => bool) tokenSupported;

    function initialize(address _router, address[] calldata _tokenSupported) public initializer {
        __Ownable_init();
        router = IUniswap(_router);
        for (uint256 index = 0; index < _tokenSupported.length; index++) {
            tokenSupported[_tokenSupported[index]] = true;
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function swapEthToToken(
        address tokenAddress,
        address to,
        uint256 amount,
        uint256 deadline
    ) public returns (uint256) {
        assert(tokenSupported[tokenAddress]);
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = tokenAddress;

        uint256[] memory amounts = router.swapETHForExactTokens(amount, path, to, deadline);
        return amounts[0];
    }
}
