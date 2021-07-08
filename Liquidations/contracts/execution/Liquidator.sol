pragma solidity >=0.6.0;

import "../external/IERC20.sol";
import "../external/ILendingPoolAddressesProvider.sol";
import "../external/ILendingPool.sol";
import "./FlashLoanReceiverBase.sol";

contract Liquidator is FlashLoanReceiverBase {
    using SafeMath for uint256;

    address constant lendingPoolAddressProvider = INSERT_LENDING_POOL_ADDRESS;
    address payable owner;

    constructor(ILendingPoolAddressesProvider _addressProvider)
        public
        FlashLoanReceiverBase(_addressProvider)
    {
        owner = payable(msg.sender);
        lendingPoolAddressProvider = _addressProvider;

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }

     function withdrawEth() public onlyOwner {
        owner.transfer(address(this).balance);
    }

    //Withdraw a specific ERC20 token
    function withdrawErc20(address token) external onlyOwner {
        IERC20 newToken = IERC20(token);
        newToken.transfer(owner, newToken.balanceOf(address(this)));
    }

    //Change the contract owner
    function changeOwner(address payable newOwner) external onlyOwner {
        owner = newOwner;
    }

    //CALLBACK AFTER RECEIVING FLASHLOAN
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {

        //Decode params
        (address _user, address _collateral, bool _receiveaToken) =
            abi.decode(params, (address, address, bool));

        myLiquidationFunction(
            _collateral,
            assets[0],
            _user,
            amounts[0],
            _receiveaToken
        );

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }

    function myFlashLoanCall(
        address token,
        uint256 amount,
        bytes calldata params
    ) external {
        address[] memory assets = new address[](1);
        assets[0] = address(token);

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;

        LENDING_POOL.flashLoan(
            address(this), //receiverAddress
            assets,
            amounts,
            modes,
            address(this), //onBehalfOf
            params,
            0 //referralCode
        );
    }

    //PERFORMS LIQUIDATION
    function myLiquidationFunction(
        address _collateral,
        address _reserve,
        address _user,
        uint256 _purchaseAmount,
        bool _receiveaToken
    ) external {
        ILendingPoolAddressesProvider addressProvider =
            ILendingPoolAddressesProvider(lendingPoolAddressProvider);

        ILendingPool lendingPool =
            ILendingPool(addressProvider.getLendingPool());

        require(
            IERC20(_reserve).approve(address(lendingPool), _purchaseAmount),
            "Approval error"
        );

        // Assumes this contract already has `_purchaseAmount` of `_reserve`.
        lendingPool.liquidationCall(
            _collateral,
            _reserve,
            _user,
            _purchaseAmount,
            _receiveaToken
        );
    }

    fallback() external payable {}

    receive() external payable {}
}
