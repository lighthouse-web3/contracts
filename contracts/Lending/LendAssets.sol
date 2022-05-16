import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// AAVE
import "./AAVE-Interfaces/ILendingPool.sol";
import "./AAVE-Interfaces/ILendingPoolAddressesProvider.sol";
import "./AAVE-Interfaces/IAToken.sol";