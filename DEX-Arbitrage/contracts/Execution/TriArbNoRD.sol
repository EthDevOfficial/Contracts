pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../External/IERC20.sol";
import "../External/Uniswap.sol";
import "../External/Pancake.sol";
import "../External/Pangolin.sol";
import "../External/ApeSwap.sol";
import "../External/DXSwap.sol";
import "../External/JetSwap.sol";

contract TriArbNoRD is
    IUniswapV2Callee,
    IPancakeCallee,
    IPangolinCallee,
    IApeCallee,
    IDXswapCallee,
    IJetswapCallee
{
    address payable owner;

    struct TradeObject {
        address token1;
        address token2;
        address token3;
        address token4;
        address pool1;
        address pool2;
        address pool3;
        address pool4;
        uint256 input;
        uint256 output1;
        uint256 output2;
        uint256 output3;
        uint256 output4;
    }

    //Create modifier to limit who can call the contract
    modifier onlyOwner() {
        require(msg.sender == owner, "Sender not authorized.");
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }

    //Create address variables for relevant exchanges
    constructor() public payable {
        owner = payable(msg.sender);
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

    function callBack(bytes memory data) internal {
        TradeObject memory trade = abi.decode(data, (TradeObject));

        IERC20(trade.token2).transfer(trade.pool2, trade.output1);

        //Tris and quads
        if (trade.pool2 != trade.pool3) {
            //If token1 is first token for uniswap pool, we want an output of 0 for that token
            if (trade.token2 < trade.token3) {
                IUniswapV2Pair(trade.pool2).swap(
                    0,
                    trade.output2,
                    trade.pool3, //send funds to next pool
                    new bytes(0)
                );
            } else {
                IUniswapV2Pair(trade.pool2).swap(
                    trade.output2,
                    0,
                    trade.pool3, //send funds to next pool
                    new bytes(0)
                );
            }
            //Quads
            if (trade.pool3 != trade.pool4) {
                if (trade.token3 < trade.token4) {
                    IUniswapV2Pair(trade.pool3).swap(
                        0,
                        trade.output3,
                        trade.pool4, //send funds to next pool
                        new bytes(0)
                    );
                } else {
                    IUniswapV2Pair(trade.pool3).swap(
                        trade.output3,
                        0,
                        trade.pool4, //send funds to next pool
                        new bytes(0)
                    );
                }

                if (trade.token4 < trade.token1) {
                    IUniswapV2Pair(trade.pool4).swap(
                        0,
                        trade.output4,
                        address(this),
                        new bytes(0)
                    );
                } else {
                    IUniswapV2Pair(trade.pool4).swap(
                        trade.output4,
                        0,
                        address(this),
                        new bytes(0)
                    );
                }
                //Finish tris
            } else {
                if (trade.token3 < trade.token1) {
                    IUniswapV2Pair(trade.pool3).swap(
                        0,
                        trade.output3,
                        address(this),
                        new bytes(0)
                    );
                } else {
                    IUniswapV2Pair(trade.pool3).swap(
                        trade.output3,
                        0,
                        address(this),
                        new bytes(0)
                    );
                }
            }
        } else {
            //Simples
            if (trade.token2 < trade.token1) {
                IUniswapV2Pair(trade.pool2).swap(
                    0,
                    trade.output2,
                    address(this),
                    new bytes(0)
                );
            } else {
                IUniswapV2Pair(trade.pool2).swap(
                    trade.output2,
                    0,
                    address(this),
                    new bytes(0)
                );
            }
        }

        //Return owed amount to first exchange.
        //This function is called back by the exchange we need to repay the flashloan to, so we can use msg.sender
        IERC20(trade.token1).transfer(
            msg.sender, 
            trade.input
        );
    }

    function DXswapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        callBack(data);
    }

    function jetswapCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        callBack(data);
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

    //Callback from apeSwap callback
    function apeCall(
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
    function initiateTrade(bytes calldata data) public {
        TradeObject memory trade = abi.decode(data, (TradeObject));

        if (trade.token1 < trade.token2) {
            IUniswapV2Pair(trade.pool1).swap(
                0,
                trade.output1,
                address(this), //For some reason you cant send directly to next pool
                data //calldata
            );
        } else {
            IUniswapV2Pair(trade.pool1).swap(
                trade.output1,
                0,
                address(this),
                data //calldata
            );
        }
    }

    fallback() external payable {}

    receive() external payable {}
}
