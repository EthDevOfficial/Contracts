pragma solidity >=0.6.0;
// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
import '../External/Uniswap.sol';
import './OptimizersReturn.sol';
import "../External/IERC20.sol";
import "../Execution/TriArbNoRD.sol";
import "../External/ABDK.sol";

contract OptimizerReturn {
	using SafeMath for uint256;
	address UniswapFactoryAddress; //For converting to std
	address payable owner;
	// bytes16 MP_MULT_DIVISOR;
	bytes16 ONE_AS_BYTES;

	struct SimpleCall {
		address outerToken;
		address innerToken;
		address exchange1;
		address exchange2;
		//uint256 mpMultiplier;
	}

	// struct TriCall {
	// 	address token1;
	// 	address token2;
	// 	address token3;
	// 	address exchange1;
	// 	address exchange2;
	// 	address exchange3;
	// 	//uint256 mpMultiplier;
	// }

	struct Opportunity {
		address outerToken;
		address innerToken;
		address awayPool;
		address returnPool;
		uint256 inputWei;
		uint256 innerWei;
		uint256 outputWei;
		uint256 diff;
	}

	// struct TriOpportunity {
	// 	address token1;
	// 	address token2;
	// 	address token3;
	// 	address pool1;
	// 	address pool2;
	// 	address pool3;
	// 	uint256 input1;
	// 	uint256 output1; // == input2
	// 	uint256 output2; // == input 3
	// 	uint256 output3;
	// 	uint256 diff;
	// }


	struct OptimalInfo {
		address tokenIn;
		address tokenOut;
		uint256 optimalInput;
		uint256 optimalOutput;
		uint256 reserveIn;
		uint256 reserveOut;
		bytes16 preMP;
		// bytes16 rootMP;
		address poolAddress;
		address factory;
	}

	struct TestingReturn {
		address outerToken;
		address innerToken;
		uint256 input1;
		uint256 output1;
		uint256 input2;
		uint256 output2;
	}

	event simpleOppEvent(
		address token1,
		address token2,
		uint256 inputWei,
		uint256 innerWei,
		uint256 outputWei,
		uint256 diff
		);

	// event getCornerEvent(
	// 	address tokenIn,
	// 	address tokenOut,
	// 	uint256 inputWei,
	// 	uint256 outputWei
	// );

	// event triOppEvent(
	// 	address token1,
	// 	address token2,
	// 	address token3,
	// 	uint256 input1,
	// 	uint256 output1, // == input2
	// 	uint256 output2, // == input 3
	// 	uint256 output3,
	// 	uint256 diff
	// );

	event ErrorHandled(string reason);

	//Create modifier to limit who can call the contract
	modifier onlyOwner() {
		require(msg.sender == owner, 'Sender not authorized.');
		// Do not forget the "_;"! It will
		// be replaced by the actual function
		// body when the modifier is used.
		_;
	}

	constructor(address uniswapFactory) payable {
		UniswapFactoryAddress = uniswapFactory;
		owner = payable(msg.sender);
		// MP_MULT_DIVISOR = ABDKFloat.fromUInt(10000);
		ONE_AS_BYTES = ABDKFloat.fromUInt(1);
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

	//Change the router address
	function changeUniswapFactory(address newAddress) external onlyOwner {
		UniswapFactoryAddress = newAddress;
	}

	function simpleMulticall(bytes[] calldata calls, address stdToken) external returns (bytes[] memory ret) {
		ret = new bytes[](calls.length);
		for (uint i = 0; i < calls.length; i++) {
			ret[i] = getOpportunityFromCall(calls[i], stdToken);
		}
  }

	// function triMulticall(bytes[] calldata calls, address stdToken) external returns (bytes[] memory ret) {
	// 	ret = new bytes[](calls.length);
	// 	for (uint i = 0; i < calls.length; i++) {
	// 		ret[i] = getTriOpportunityFromCall(calls[i], stdToken);
	// 	}
  // }

	function getOpportunityFromCall(
		bytes memory call,
 		address stdToken
	) internal  returns (bytes memory) {
		SimpleCall memory params = abi.decode(call, (SimpleCall));
		return abi.encode(getOpportunityTest(params, stdToken));
	}

	// function getTriOpportunityFromCall(
	// 	bytes memory call,
 	// 	address stdToken
	// ) internal  returns (bytes memory) {
	// 	TriCall memory params = abi.decode(call, (TriCall));
	// 	return abi.encode(getTriOpportunity(params, stdToken));
	// }

	function getOpportunityTest(
		SimpleCall memory params,
 		address stdToken
	) internal view returns (TestingReturn memory) {
		OptimalInfo memory awayInfo = OptimalInfo(
			params.outerToken, // tokenIn
			params.innerToken, // tokenOut
			0, // optimalInput
			0, // optimalOutput
			0, // reserveIn 
			0, // reserveOut
			bytes16(0), // preMP
			// bytes16(0),// rootMP
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange1).factory()
		);
		OptimalInfo memory returnInfo = OptimalInfo(
			params.innerToken, // tokenIn
			params.outerToken, // tokenOut
			0, // optimalInput
			0, // optimalOutput
			0, // reserveIn 
			0, // reserveOut
			bytes16(0), // preMP
			// bytes16(0),// rootMP
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange2).factory()
		);
		awayInfo = getAlmostAllOptimalInfo(awayInfo);
		returnInfo = getAlmostAllOptimalInfo(returnInfo);

		if (awayInfo.reserveIn <= 0 || awayInfo.reserveOut <= 0 || returnInfo.reserveIn <= 0 || returnInfo.reserveOut <= 0) {
			return TestingReturn(
				awayInfo.tokenIn, // outerToken
				awayInfo.tokenOut, // innerToken
				0, // input1
				0, // output1
				0, // input2
				0 // output2
			);
		}

		bytes16 rootMP = OptimizersReturn.getAvgRootMP(
			awayInfo.reserveIn, 
			returnInfo.reserveOut, 
			awayInfo.reserveOut,
			returnInfo.reserveIn
		);

		// 	Multiplying optimal away output by return mp, multiplying optimal return output by away mp
		awayInfo.optimalOutput = OptimizersReturn.getUniOutputGivenMp(awayInfo.preMP, rootMP, awayInfo.reserveOut);
		if (awayInfo.optimalOutput > 0) {
			awayInfo.optimalInput = IUniswapV2Router02(params.exchange1).getAmountIn(awayInfo.optimalOutput, awayInfo.reserveIn, awayInfo.reserveOut);
			// emit getCornerEvent(awayInfo.tokenIn, awayInfo.tokenOut, awayInfo.optimalInput, awayInfo.optimalOutput);
		} else {
			return TestingReturn(
				awayInfo.tokenIn, // outerToken
				awayInfo.tokenOut, // innerToken
				0, // input1
				0, // output1
				0, // input2
				0 // output2
			);
		}

		returnInfo.optimalOutput = OptimizersReturn.getUniOutputGivenMp(returnInfo.preMP, ABDKFloat.div(ONE_AS_BYTES, rootMP), returnInfo.reserveOut);
		if(returnInfo.optimalOutput > 0){
			returnInfo.optimalInput = IUniswapV2Router02(params.exchange2).getAmountIn(returnInfo.optimalOutput, returnInfo.reserveIn, returnInfo.reserveOut);
			// emit getCornerEvent(returnInfo.tokenIn, returnInfo.tokenOut, returnInfo.optimalInput, returnInfo.optimalOutput);
		} else {
			return TestingReturn(
				awayInfo.tokenIn, // outerToken
				awayInfo.tokenOut, // innerToken
				0, // input1
				0, // output1
				0, // input2
				0 // output2
			);
		}
		return TestingReturn(
			awayInfo.tokenIn, // outerToken
			awayInfo.tokenOut, // innerToken
			awayInfo.optimalInput, // input1
			awayInfo.optimalOutput, // output1
			returnInfo.optimalInput, // input2
			returnInfo.optimalOutput // output2
		);
	}

	function getOpportunity(
		SimpleCall memory params,
 		address stdToken
	) internal	 returns (Opportunity memory) {
		OptimalInfo memory awayInfo = OptimalInfo(
			params.outerToken, // tokenIn
			params.innerToken, // tokenOut
			0, // optimalInput
			0, // optimalOutput
			0, // reserveIn 
			0, // reserveOut
			bytes16(0), // preMP
			// bytes16(0),// rootMP
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange1).factory()
		);
		OptimalInfo memory returnInfo = OptimalInfo(
			params.innerToken, // tokenIn
			params.outerToken, // tokenOut
			0, // optimalInput
			0, // optimalOutput
			0, // reserveIn 
			0, // reserveOut
			bytes16(0), // preMP
			// bytes16(0),// rootMP
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange2).factory()
		);
		awayInfo = getAlmostAllOptimalInfo(awayInfo);
		returnInfo = getAlmostAllOptimalInfo(returnInfo);

		if (awayInfo.reserveIn <= 0 || awayInfo.reserveOut <= 0 || returnInfo.reserveIn <= 0 || returnInfo.reserveOut <= 0) {
			return Opportunity(
				awayInfo.tokenIn, 
				awayInfo.tokenOut, 
				awayInfo.poolAddress,
				returnInfo.poolAddress, 
				awayInfo.optimalInput, 
				awayInfo.optimalOutput, 
				returnInfo.optimalOutput, 
				0
			);
		}

		bytes16 rootMP = OptimizersReturn.getAvgRootMP(
			awayInfo.reserveIn, 
			returnInfo.reserveOut, 
			awayInfo.reserveOut,
			returnInfo.reserveIn
		);

		// 	Multiplying optimal away output by return mp, multiplying optimal return output by away mp
		awayInfo.optimalOutput = OptimizersReturn.getUniOutputGivenMp(awayInfo.preMP, rootMP, awayInfo.reserveOut);
		if (awayInfo.optimalOutput > 0) {
			awayInfo.optimalInput = IUniswapV2Router02(params.exchange1).getAmountIn(awayInfo.optimalOutput, awayInfo.reserveIn, awayInfo.reserveOut);
			// emit getCornerEvent(awayInfo.tokenIn, awayInfo.tokenOut, awayInfo.optimalInput, awayInfo.optimalOutput);
		} else {
			return Opportunity(
				awayInfo.tokenIn, 
				awayInfo.tokenOut, 
				awayInfo.poolAddress,
				returnInfo.poolAddress, 
				awayInfo.optimalInput, 
				awayInfo.optimalOutput, 
				returnInfo.optimalOutput, 
				0
			);
		}

		returnInfo.optimalOutput = OptimizersReturn.getUniOutputGivenMp(returnInfo.preMP, ABDKFloat.div(ONE_AS_BYTES, rootMP), returnInfo.reserveOut);
		if(returnInfo.optimalOutput > 0){
			returnInfo.optimalInput = IUniswapV2Router02(params.exchange2).getAmountIn(returnInfo.optimalOutput, returnInfo.reserveIn, returnInfo.reserveOut);
			// emit getCornerEvent(returnInfo.tokenIn, returnInfo.tokenOut, returnInfo.optimalInput, returnInfo.optimalOutput);
		} else {
			return Opportunity(
				awayInfo.tokenIn, 
				awayInfo.tokenOut, 
				awayInfo.poolAddress,
				returnInfo.poolAddress, 
				awayInfo.optimalInput, 
				awayInfo.optimalOutput, 
				returnInfo.optimalOutput, 
				0
			);
		}

		if (awayInfo.optimalOutput <= returnInfo.optimalInput) {
			// recalc return using away's output as input
			returnInfo.optimalOutput = IUniswapV2Router02(params.exchange2).getAmountOut(awayInfo.optimalOutput, returnInfo.reserveIn, returnInfo.reserveOut);
		} else if(returnInfo.optimalInput > 0){
			// recalc away using return's input as output
			awayInfo.optimalInput = IUniswapV2Router02(params.exchange1).getAmountIn(returnInfo.optimalInput, awayInfo.reserveIn, awayInfo.reserveOut); 
			awayInfo.optimalOutput = returnInfo.optimalInput;
		}

		uint256 diff = 0;
		
		if(returnInfo.optimalOutput > awayInfo.optimalInput){
            if(awayInfo.tokenIn != stdToken){
                address poolAddress = IUniswapV2Factory(UniswapFactoryAddress).getPair(awayInfo.tokenIn, stdToken);
                if(poolAddress == address(0)){
			        return Opportunity(
                    awayInfo.tokenIn, 
                    awayInfo.tokenOut, 
                    awayInfo.poolAddress,
                    returnInfo.poolAddress, 
                    awayInfo.optimalInput, 
                    awayInfo.optimalOutput, 
                    returnInfo.optimalOutput, 
				    0
			    );
		        }
                (address tokenA, ) = sortTokens(awayInfo.tokenIn, stdToken);
				(uint112 reserveA, uint112 reserveB, )  = IUniswapV2Pair(poolAddress).getReserves();
                (uint112 reserveIn, uint112 reserveOut) = awayInfo.tokenIn == tokenA ? (reserveA, reserveB) : (reserveB, reserveA);
				diff = reserveIn > 0 ? ABDK.mulu(ABDK.divu(reserveOut, reserveIn), returnInfo.optimalOutput - awayInfo.optimalInput): 0;
			}else{
				diff = returnInfo.optimalOutput - awayInfo.optimalInput;
			}
		}

		return Opportunity(
			awayInfo.tokenIn, 
			awayInfo.tokenOut, 
			awayInfo.poolAddress,
			returnInfo.poolAddress, 
			awayInfo.optimalInput, 
			awayInfo.optimalOutput, 
			returnInfo.optimalOutput, 
			diff
		);
	}

	// function getTriOpportunity (
	// 	TriCall memory params,
 	// 	address stdToken
	// ) internal view returns (TriOpportunity memory) {
	// 	OptimalInfo memory info1 = OptimalInfo(
	// 		params.token1, // tokenIn
	// 		params.token2, // tokenOut
	// 		0, // optimalInput
	// 		0, // optimalOutput
	// 		0, // reserveIn 
	// 		0, // reserveOut
	// 		bytes16(0), // preMP
	// 		bytes16(0),// rootMP
	// 		address(0), // poolAddress
	// 		IUniswapV2Router02(params.exchange1).factory()
	// 	);
		
	// 	OptimalInfo memory info2 = OptimalInfo(
	// 		params.token2, // tokenIn
	// 		params.token3, // tokenOut
	// 		0, // optimalInput
	// 		0, // optimalOutput
	// 		0, // reserveIn 
	// 		0, // reserveOut
	// 		bytes16(0), // preMP
	// 		bytes16(0),// rootMP
	// 		address(0), // poolAddress
	// 		IUniswapV2Router02(params.exchange2).factory()
	// 	);
		
	// 	OptimalInfo memory info3 = OptimalInfo(
	// 		params.token3, // tokenIn
	// 		params.token1, // tokenOut
	// 		0, // optimalInput
	// 		0, // optimalOutput
	// 		0, // reserveIn 
	// 		0, // reserveOut
	// 		bytes16(0), // preMP
	// 		bytes16(0),// rootMP
	// 		address(0), // poolAddress
	// 		IUniswapV2Router02(params.exchange3).factory()
	// 	);

	// 	info1 = getAlmostAllOptimalInfo(info1, params.mpMultiplier);
	// 	info2 = getAlmostAllOptimalInfo(info2, params.mpMultiplier);
	// 	info3 = getAlmostAllOptimalInfo(info3, params.mpMultiplier);

	// 	if(info1.reserveIn <= 0 || info1.reserveOut <= 0 || info2.reserveIn <= 0 || info2.reserveOut <= 0 || info3.reserveIn <= 0 || info3.reserveOut <= 0){
	// 		return TriOpportunity(
	// 			info1.tokenIn, info1.tokenOut, info2.tokenOut,
	// 			info1.poolAddress, info2.poolAddress, info3.poolAddress, 
	// 			info1.optimalInput, info1.optimalOutput, info2.optimalOutput, info3.optimalOutput, 
	// 			0
	// 		);
	// 	}

	// 	info1.optimalOutput = OptimizersReturn.getUniOutputGivenMp(info1.preMP, ABDKFloat.mul(info2.rootMP, info3.rootMP), info1.reserveOut);
	// 	if(info1.optimalOutput > 0) {
	// 		info1.optimalInput = IUniswapV2Router02(params.exchange1).getAmountIn(info1.optimalOutput, info1.reserveIn, info1.reserveOut);
	// 	} else {
	// 		return TriOpportunity(
	// 			info1.tokenIn, info1.tokenOut, info2.tokenOut,
	// 			info1.poolAddress, info2.poolAddress, info3.poolAddress, 
	// 			info1.optimalInput, info1.optimalOutput, info2.optimalOutput, info3.optimalOutput, 
	// 			0
	// 		);
	// 	}

	// 	info2.optimalOutput = OptimizersReturn.getUniOutputGivenMp(info2.preMP, ABDKFloat.mul(info3.rootMP, info1.rootMP), info2.reserveOut);
	// 	if(info2.optimalOutput > 0){
	// 		info2.optimalInput = IUniswapV2Router02(params.exchange2).getAmountIn(info2.optimalOutput, info2.reserveIn, info2.reserveOut) ;
	// 	} else {
	// 		return TriOpportunity(
	// 			info1.tokenIn, info1.tokenOut, info2.tokenOut,
	// 			info1.poolAddress, info2.poolAddress, info3.poolAddress, 
	// 			info1.optimalInput, info1.optimalOutput, info2.optimalOutput, info3.optimalOutput, 
	// 			0
	// 		);
	// 	}

	// 	info3.optimalOutput = OptimizersReturn.getUniOutputGivenMp(info3.preMP, ABDKFloat.mul(info1.rootMP, info2.rootMP), info3.reserveOut);
	// 	if(info3.optimalOutput > 0){
	// 		info3.optimalInput = IUniswapV2Router02(params.exchange3).getAmountIn(info3.optimalOutput, info3.reserveIn, info3.reserveOut) ;
	// 	} else {
	// 		return TriOpportunity(
	// 			info1.tokenIn, info1.tokenOut, info2.tokenOut,
	// 			info1.poolAddress, info2.poolAddress, info3.poolAddress, 
	// 			info1.optimalInput, info1.optimalOutput, info2.optimalOutput, info3.optimalOutput, 
	// 			0
	// 		);
	// 	}

	// 	if (info1.optimalOutput <= info2.optimalInput) {
	// 		info2.optimalOutput = IUniswapV2Router02(params.exchange2).getAmountOut(info1.optimalOutput, info2.reserveIn, info2.reserveOut);
	// 		if (info2.optimalOutput <= info3.optimalInput) {
	// 			info3.optimalOutput = IUniswapV2Router02(params.exchange3).getAmountOut(info2.optimalOutput, info3.reserveIn, info3.reserveOut);
	// 		} else {
	// 			// info3 minimal
	// 			info2.optimalOutput = info3.optimalInput;
	// 			info1.optimalOutput = IUniswapV2Router02(params.exchange2).getAmountIn(info2.optimalOutput, info2.reserveIn, info2.reserveOut);  
	// 			info1.optimalInput = IUniswapV2Router02(params.exchange1).getAmountIn(info1.optimalOutput, info1.reserveIn, info1.reserveOut);  
	// 		}
	// 	} else {
	// 		if (info2.optimalOutput <= info3.optimalInput) {
	// 			info3.optimalOutput = IUniswapV2Router02(params.exchange3).getAmountIn(info2.optimalOutput, info3.reserveIn, info3.reserveOut); 
	// 			info1.optimalInput = IUniswapV2Router02(params.exchange1).getAmountIn(info2.optimalOutput, info1.reserveIn, info1.reserveOut);  
	// 			info1.optimalOutput = info2.optimalInput;
	// 		} else {
	// 			info2.optimalOutput = info3.optimalInput;
	// 			info1.optimalOutput = IUniswapV2Router02(params.exchange2).getAmountIn(info2.optimalOutput, info2.reserveIn, info2.reserveOut);  
	// 			info1.optimalInput = IUniswapV2Router02(params.exchange1).getAmountIn(info1.optimalOutput, info1.reserveIn, info1.reserveOut);
	// 		}		
	// 	}

	// 	uint256 diff = 0;
		
	// 	if(info3.optimalOutput > info1.optimalInput){
	// 		if(info1.tokenIn != stdToken){
  //               address poolAddress = IUniswapV2Factory(UniswapFactoryAddress).getPair(info1.tokenIn, stdToken);
  //               if(poolAddress == address(0)){
	// 		        return TriOpportunity(
  //                       info1.tokenIn, info1.tokenOut, info2.tokenOut,
  //                       info1.poolAddress, info2.poolAddress, info3.poolAddress, 
  //                       info1.optimalInput, info1.optimalOutput, info2.optimalOutput, info3.optimalOutput, 
  //                       0
	// 	            );
	// 	        }
  //               (address tokenA, ) = sortTokens(info1.tokenIn, stdToken);
	// 			(uint112 reserveA, uint112 reserveB, )  = IUniswapV2Pair(poolAddress).getReserves();
  //               (uint112 reserveIn, uint112 reserveOut) = info1.tokenIn == tokenA ? (reserveA, reserveB) : (reserveB, reserveA);
	// 			diff = reserveIn > 0 ? ABDK.mulu(ABDK.divu(reserveOut, reserveIn), info3.optimalOutput - info1.optimalInput): 0;
	// 		}else{
	// 			diff = info3.optimalOutput - info1.optimalInput;
	// 		}
	// 	}
		
	// 	return TriOpportunity(
	// 		info1.tokenIn, info1.tokenOut, info2.tokenOut,
	// 		info1.poolAddress, info2.poolAddress, info3.poolAddress, 
	// 		info1.optimalInput, info1.optimalOutput, info2.optimalOutput, info3.optimalOutput, 
	// 		diff
	// 	);
	// }

	function getAlmostAllOptimalInfo(
		OptimalInfo memory info
		//uint256 mpMultiplier
	) internal view returns (OptimalInfo memory optimalInfo) {
		//Get pool address, if it doesnt exist, return empty info which causes exit 
		info.poolAddress = IUniswapV2Factory(info.factory).getPair(info.tokenIn, info.tokenOut);
		if(info.poolAddress == address(0)){
			return info;
		}

		{
			//Get reserves for tokenIn and tokenOut and orders them correctly.
			(address tokenA, ) = sortTokens(info.tokenIn, info.tokenOut);
			(uint112 reserveA, uint112 reserveB, )  = IUniswapV2Pair(info.poolAddress).getReserves();
			(info.reserveIn, info.reserveOut) = info.tokenIn == tokenA ? (reserveA, reserveB) : (reserveB, reserveA); //Get reserve order
			delete tokenA;
			delete reserveA;
			delete reserveB;
		}

		//If either reserve is 0 then we should exit, no opp is possible on this route
		if(info.reserveIn <= 0 || info.reserveOut <= 0 ){
			return info;
		}

		info.preMP = OptimizersReturn.getUniOptimalPreMP(info);
		// info.rootMP = ABDKFloat.sqrt(ABDKFloat.div(ABDKFloat.fromUInt(info.reserveOut), ABDKFloat.fromUInt(info.reserveIn)));
		return info;
	}

	function sortTokens(address tokenIn, address tokenOut)
        internal
        pure
        returns (address tokenA, address tokenB)
    {
        require(tokenIn != tokenOut, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (tokenA, tokenB) = tokenIn < tokenOut
            ? (tokenIn, tokenOut)
            : (tokenOut, tokenIn);
        require(tokenA != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

	fallback() external payable {}

    receive() external payable {}
}
