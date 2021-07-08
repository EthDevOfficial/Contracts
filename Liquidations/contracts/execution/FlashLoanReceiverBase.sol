pragma solidity >=0.6.0;

import "../external/ILendingPool.sol";
import "../external/IERC20.sol";
import "../external/ILendingPoolAddressesProvider.sol";
import "../external/SafeMath.sol";
import "../external/SafeERC20.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  ILendingPoolAddressesProvider public immutable override ADDRESSES_PROVIDER;
  ILendingPool public immutable override LENDING_POOL;

  constructor(ILendingPoolAddressesProvider provider) public {
    ADDRESSES_PROVIDER = provider;
    LENDING_POOL = ILendingPool(provider.getLendingPool());
  }
}