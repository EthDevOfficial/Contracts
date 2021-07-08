pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../External/IERC20.sol";
import "../External/Uniswap.sol";
import "../External/Pancake.sol";
import "../External/Pangolin.sol";
import "../External/ChiToken.sol";

contract TriArbChi is IUniswapV2Callee, IPancakeCallee, IPangolinCallee {

    address payable owner;
    ChiToken public chi; 

    //Create modifier to limit who can call the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    modifier discountCHI {
        uint256 gasStart = gasleft();

        _;

        uint256 initialGas = 21000 + 16 * msg.data.length;
        uint256 gasSpent = initialGas + gasStart - gasleft();
        uint256 freeUpValue = (gasSpent + 14154) / 41947;

        chi.freeUpTo(freeUpValue);
    }

    //Create address variables for relevant exchanges
    constructor(address ChiAddress) public payable {
        owner = payable(msg.sender);
        chi = ChiToken(ChiAddress);
    }

    //Withdraws any ethereum from the address
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

    function callBack(
        bytes memory data
    ) internal {
        (
            address token1
            ,address token2
            ,address token3
            ,
            ,address pool2
            ,address pool3
            ,uint256 input
            ,uint256 output1
            ,uint256 output2
            ,uint256 output3
        ) = abi.decode(data, (address,address,address,address,address,address,uint256,uint256,uint256,uint256));

        IERC20(token2).transfer(pool2, output1);

        if (pool2 != pool3) {
            //If token1 is first token for uniswap pool, we want an output of 0 for that token
            if (token2 < token3) {
                IUniswapV2Pair(pool2).swap(
                    0,
                    output2,
                    pool3, //send funds to next pool
                    new bytes(0)
                );
            } else {
                IUniswapV2Pair(pool2).swap(
                    output2,
                    0,
                    pool3, //send funds to next pool
                    new bytes(0)
                );
            }
            if (token3 < token1) {
                IUniswapV2Pair(pool3).swap(
                    0,
                    output3,
                    address(this),
                    new bytes(0)
                );
            } else {
                IUniswapV2Pair(pool3).swap(
                    output3,
                    0,
                    address(this),
                    new bytes(0)
                );
            }
        } else {
            if (token2 < token1) {
                IUniswapV2Pair(pool2).swap(
                    0,
                    output2,
                    address(this),
                    new bytes(0)
                );
            } else {
                IUniswapV2Pair(pool2).swap(
                    output2,
                    0,
                    address(this),
                    new bytes(0)
                );
            }
        }

        //Return owed amount to first exchange.
        IERC20(token1).transfer(
            msg.sender, //This function is called back by the exchange we need to repay the flashloan to, so we can use msg.sender
            input
        );
            delete token1;
            delete token2;
            delete token3;
            delete pool2;
            delete pool3;
            delete input;
            delete output1;
            delete output2;
            delete output3;
    }

    //Callback from uniswap or sushiswap pool flashloan
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        callBack(data);
    }

    //Callback from panckaeSwap callback
    function pancakeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        callBack(data);      
    }

    //Callback from pangolinSwap callback
    function pangolinCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        callBack(data);      
    }

    //This is the function that initiates the arbitrage play
    function initiateTrade(bytes calldata data) public discountCHI {
        (
            address token1
            ,address token2
            ,
            ,address pool1
            ,
            ,
            ,
            ,uint256 output1
            ,
            ,
        ) = abi.decode(data, (address,address,address,address,address,address,uint256,uint256,uint256,uint256));

        if (token1 < token2) {
            IUniswapV2Pair(pool1).swap(
                0,
                output1,
                address(this), //For some reason you cant send directly to next pool
                data //calldata
            );
        } else {
            IUniswapV2Pair(pool1).swap(
                output1,
                0,
                address(this),
                data //calldata
            );
        }
        delete token1;
        delete token2;
        delete pool1;
        delete output1;
    }

    fallback() external payable {}

    receive() external payable {}
}
