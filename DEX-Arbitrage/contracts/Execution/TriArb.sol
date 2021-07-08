pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

import "../External/IERC20.sol";
import "../External/Uniswap.sol";

contract TriArb is IUniswapV2Callee {
    struct ArbInfoParameter {
        address _token1;
        address _token2;
        address _token3;
        address _pool1;
        address _pool2;
        address _pool3;
        uint112 _input;
        uint112 _output1_0;
        uint112 _output1_1;
        uint112 _output2_0;
        uint112 _output2_1;
        uint112 _output3_0;
        uint112 _output3_1;
        uint112 _reserve1;
        uint112 _reserve2;
        uint112 _reserve3;
        uint8 triarb;
    }

    address payable owner;

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
        owner = msg.sender;
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

    //Callback from uniswap or sushiswap pool flashloan
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
        ArbInfoParameter memory arbInfo = abi.decode(data, (ArbInfoParameter));

        if (arbInfo._output1_0 > arbInfo._output1_1) {
            IERC20(arbInfo._token2).transfer(
                arbInfo._pool2,
                arbInfo._output1_0
            );
        } else {
            IERC20(arbInfo._token2).transfer(
                arbInfo._pool2,
                arbInfo._output1_1
            );
        }

        if (arbInfo.triarb == 1) {
            IUniswapV2Pair(arbInfo._pool2).swap(
                arbInfo._output2_0,
                arbInfo._output2_1,
                arbInfo._pool3, //send funds to next pool
                new bytes(0)
            );
            IUniswapV2Pair(arbInfo._pool3).swap(
                arbInfo._output3_0,
                arbInfo._output3_1,
                address(this), //If this is last swap, return output to this contract
                new bytes(0) //pass bytes(0) to do swap instead of flashswap
            );
        } else {
            IUniswapV2Pair(arbInfo._pool2).swap(
                arbInfo._output2_0,
                arbInfo._output2_1,
                address(this), //If this is last swap, return output to this contract
                new bytes(0) //pass bytes(0) to do swap instead of flashswap
            );
        }

        //Return owed amount to first exchange.
        IERC20(arbInfo._token1).transfer(
            msg.sender, //This function is called back by the exchange we need to repay the flashloan to, so we can use msg.sender
            arbInfo._input
        );
    }

    //This is the function that initiates the arbitrage play
    function initiateTrade(bytes calldata data) external {
        ArbInfoParameter memory AIP = abi.decode(data, (ArbInfoParameter));

        (uint112 reserve1, , ) = IUniswapV2Pair(AIP._pool1).getReserves();
        (uint112 reserve2, , ) = IUniswapV2Pair(AIP._pool2).getReserves();
        if (AIP.triarb == 0) {
            require(
                reserve1 == AIP._reserve1 && reserve2 == AIP._reserve2,
                "Reserve Discrepancy"
            );
        } else {
            (uint112 reserve3, , ) = IUniswapV2Pair(AIP._pool3).getReserves();
            require(
                reserve1 == AIP._reserve1 &&
                    reserve2 == AIP._reserve2 &&
                    reserve3 == AIP._reserve3,
                "Reserve Discrepancy"
            );
        }

        //Flashswap, pass calldata
        IUniswapV2Pair(AIP._pool1).swap(
            AIP._output1_0,
            AIP._output1_1,
            address(this),
            data //calldata
        );

        // IERC20(AIP._params[AIP._params.length -1]._outputToken).transfer(
        //     owner,
        //     IERC20(AIP._params[AIP._params.length -1]._outputToken).balanceOf(address(this))
        // ); //WITHDRAW PROFIT
    }

    fallback() external payable {}

    receive() external payable {}
}
