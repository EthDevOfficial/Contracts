pragma solidity >=0.6.0;
// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
import '../External/Uniswap.sol';
import "../External/IERC20.sol";
import "../Execution/TriArbNoRD.sol";
import "../External/ChiToken.sol";

contract OptimizerTrade {
	address UniswapFactoryAddress; //For converting to std
	address payable public owner;
	address payable execContract;
	bytes16 NEG_1;
	uint256 INPUT_STEP_DIVISOR;
	uint MAX_ITERATIONS;
	bytes16 ITERATOR_THRESHOLD;
	uint256 MIN_RESERVE;
	ChiToken public chi; 

	struct SimpleCall {
		address outerToken;
		address innerToken;
		address exchange1;
		address exchange2;
		uint256 swapFeeSum;
	}

	struct TriCall {
		address token1;
		address token2;
		address token3;
		address exchange1;
		address exchange2;
		address exchange3;
		uint256 swapFeeSum;
	}

	struct Opportunity {
		address outerToken;
		address innerToken;
		address awayPool;
		address returnPool;
		uint256 inputWei;
		uint256 innerWei;
		uint256 outputWei;
	}

	struct TriOpportunity {
		address token1;
		address token2;
		address token3;
		address pool1;
		address pool2;
		address pool3;
		uint256 input1;
		uint256 output1; // == input2
		uint256 output2; // == input 3
		uint256 output3;
	}

	struct Iter {
		uint iterator;
		bytes16 targetImbalance;
		bytes16 postStepImbalance;
	}

	struct TriIteratorInputs {
		TriCall params;
		bytes16 initImbalance;
		OptimalInfo info1;
		OptimalInfo info2;
		OptimalInfo info3;
	}

	struct OptimalInfo {
		address tokenIn;
		address tokenOut;
		uint256 input;
		uint256 output;
		uint256 reserveIn;
		uint256 reserveOut;
		address poolAddress;
		address factory;
	}

	event ErrorHandled(string reason);

	//Create modifier to limit who can call the contract
	modifier onlyOwner() {
		require(msg.sender == owner, 'Sender not authorized.');
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

	constructor(address uniswapFactory, address payable exec) payable {
		execContract = exec;
		UniswapFactoryAddress = uniswapFactory;
		owner = payable(msg.sender);
		NEG_1 = ABDKFloat.sub(ABDKFloat.fromUInt(0), ABDKFloat.fromUInt(1));
		INPUT_STEP_DIVISOR = 1000000000;
		MAX_ITERATIONS = 3;
		ITERATOR_THRESHOLD = ABDKFloat.div(ABDKFloat.fromUInt(5), ABDKFloat.fromUInt(10000)); // .0005
		chi = ChiToken(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);
		MIN_RESERVE = 10000000; // 10 * 10 ^ 7
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

	function changeInputStepDivisor(uint256 divisor) external onlyOwner {
		INPUT_STEP_DIVISOR = divisor;
	}

	function simpleMulticallChi(bytes[] calldata calls) external discountCHI{
		for (uint i = 0; i < calls.length; i++) {
			getOpportunityFromCall(calls[i]);
		}
  	}

	function triMulticallChi(bytes[] calldata calls) external discountCHI{
		for (uint i = 0; i < calls.length; i++) {
			getTriOpportunityFromCall(calls[i]);
		}
  	}

	function simpleMulticall(bytes[] calldata calls) external{
		for (uint i = 0; i < calls.length; i++) {
			getOpportunityFromCall(calls[i]);
		}
  	}

	function triMulticall(bytes[] calldata calls) external{
		for (uint i = 0; i < calls.length; i++) {
			getTriOpportunityFromCall(calls[i]);
		}
  	}

	function getOpportunityFromCall(
		bytes memory call
	) internal{
		SimpleCall memory params = abi.decode(call, (SimpleCall));
		Opportunity memory opp = getSimpleOpportunity(params);
		if(opp.outputWei > opp.inputWei){
			try TriArbNoRD(execContract).initiateTrade(abi.encode(opp.outerToken, opp.innerToken, opp.innerToken, opp.awayPool, opp.returnPool, opp.returnPool, opp.inputWei, opp.innerWei, opp.outputWei, 0)){}
			catch Error(string memory reason){
				emit ErrorHandled(reason);
			}catch{
				emit ErrorHandled('Caught with no error');
			}
		}
	}

	function getTriOpportunityFromCall(
		bytes memory call
	) internal{
		TriCall memory params = abi.decode(call, (TriCall));
		TriOpportunity memory opp = getTriOpportunity(params);
		if(opp.output3 > opp.input1){
			try TriArbNoRD(execContract).initiateTrade(abi.encode(opp.token1, opp.token2, opp.token3, opp.pool1, opp.pool2, opp.pool3, opp.input1, opp.output1, opp.output2, opp.output3)){}
			catch Error(string memory reason){
				emit ErrorHandled(reason);
			}catch{
				emit ErrorHandled('Caught with no error');
			}
		}
	}

	function getOptimalInfo(OptimalInfo memory info) internal view returns (OptimalInfo memory optimalInfo) {
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
		}

		return info;
	}

	function getImbalance(
		uint256 reserve1A, 
		uint256 reserve1B,
		uint256 reserve2A,
		uint256 reserve2B
	) internal pure returns (bytes16) {
		bytes16 numerator = ABDKFloat.mul(ABDKFloat.fromUInt(reserve2A), ABDKFloat.fromUInt(reserve1B));
		bytes16 denom = ABDKFloat.mul(ABDKFloat.fromUInt(reserve2B), ABDKFloat.fromUInt(reserve1A));
		return ABDKFloat.sub(ABDKFloat.div(numerator, denom), ABDKFloat.fromUInt(1));
	}

	function getSimpleTradeIterator(
		OptimalInfo memory awayInfo,
		OptimalInfo memory returnInfo,
		SimpleCall memory params,
		bytes16 initImbalance
	) internal view returns (
		uint256 input,
		uint256 out1in2,
		uint256 output
	) {
		bytes16 targetImbalance = ABDKFloat.div(ABDKFloat.fromUInt(params.swapFeeSum), ABDKFloat.fromUInt(10000));
		input = awayInfo.reserveIn > INPUT_STEP_DIVISOR ? awayInfo.reserveIn / INPUT_STEP_DIVISOR : 1000;
		out1in2 = IUniswapV2Router02(params.exchange1).getAmountOut(input, awayInfo.reserveIn, awayInfo.reserveOut);
		output = out1in2 > 0 ? IUniswapV2Router02(params.exchange2).getAmountOut(out1in2, returnInfo.reserveIn, returnInfo.reserveOut) : 0;
		if (output == 0) {
			return (0, 0, 0);
		}
		bytes16 postStepImbalance = getImbalance(
			awayInfo.reserveIn + input,
			awayInfo.reserveOut - out1in2,
			returnInfo.reserveOut - output,
			returnInfo.reserveIn + out1in2
		);
		for (uint i = 0; i < MAX_ITERATIONS; i++) {
			input = ABDKFloat.toUInt(
				ABDKFloat.mul(
					ABDKFloat.sub(initImbalance, targetImbalance),
					ABDKFloat.div(ABDKFloat.fromUInt(input), ABDKFloat.sub(initImbalance, postStepImbalance))
				)
			);
			out1in2 = input > 0 ? IUniswapV2Router02(params.exchange1).getAmountOut(input, awayInfo.reserveIn, awayInfo.reserveOut) : 0;
			output = out1in2 > 0 ? IUniswapV2Router02(params.exchange2).getAmountOut(out1in2, returnInfo.reserveIn, returnInfo.reserveOut) : 0;
			if (output == 0) {
				return (0, 0, 0);
			}
			postStepImbalance = getImbalance(
				awayInfo.reserveIn + input,
				awayInfo.reserveOut - out1in2,
				returnInfo.reserveOut - output,
				returnInfo.reserveIn + out1in2
			);
			if (ABDKFloat.cmp(ITERATOR_THRESHOLD, ABDKFloat.abs(ABDKFloat.sub(postStepImbalance, targetImbalance))) == 1) {
				return (input, out1in2, output);
			}
		}
		return (input, out1in2, output);
	}

	function getSimpleOpportunity(
		SimpleCall memory params
		//uint256 portion
	) internal view returns (Opportunity memory) {
		OptimalInfo memory awayInfo = OptimalInfo(
			params.outerToken, // tokenIn
			params.innerToken, // tokenOut
			0, // input
			0, // output
			0, // reserveIn 
			0, // reserveOut
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange1).factory()
		);

		awayInfo = getOptimalInfo(awayInfo);

		if(awayInfo.reserveIn <= MIN_RESERVE || awayInfo.reserveOut <= MIN_RESERVE){
			return Opportunity(
				awayInfo.tokenIn, 
				awayInfo.tokenOut, 
				awayInfo.poolAddress,
				address(0),
				awayInfo.input,
				awayInfo.output,
				0
			);
		}

		OptimalInfo memory returnInfo = OptimalInfo(
			params.innerToken, // tokenIn
			params.outerToken, // tokenOut
			0, // optimalInput
			0, // optimalOutput
			0, // reserveIn 
			0, // reserveOut
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange2).factory()
		);

		returnInfo = getOptimalInfo(returnInfo);

		if(returnInfo.reserveIn <= MIN_RESERVE || returnInfo.reserveOut <= MIN_RESERVE){
			return Opportunity(
				awayInfo.tokenIn, 
				awayInfo.tokenOut, 
				awayInfo.poolAddress,
				returnInfo.poolAddress,
				awayInfo.input,
				awayInfo.output,
				0
			);
		}

		bytes16 imbalance = getImbalance(
			awayInfo.reserveIn,
			awayInfo.reserveOut,
			returnInfo.reserveOut,
			returnInfo.reserveIn
		);

		if (ABDKFloat.cmp(imbalance, ABDKFloat.div(ABDKFloat.fromUInt(params.swapFeeSum), ABDKFloat.fromUInt(10000))) != 1) {
			return Opportunity(
				awayInfo.tokenIn, 
				awayInfo.tokenOut, 
				awayInfo.poolAddress,
				returnInfo.poolAddress,
				awayInfo.input,
				awayInfo.output,
				0
			);
		}

		(awayInfo.input, awayInfo.output, returnInfo.output) = getSimpleTradeIterator(awayInfo, returnInfo, params, imbalance);

		return Opportunity(
			awayInfo.tokenIn, 
			awayInfo.tokenOut, 
			awayInfo.poolAddress,
			returnInfo.poolAddress,
			awayInfo.input,
			awayInfo.output,
			returnInfo.output
		);
	}

	function getTriImbalance(
		uint256 reserve1A, 
		uint256 reserve1B,
		uint256 reserve2B,
		uint256 reserve2C,
		uint256 reserve3C,
		uint256 reserve3A
	) internal pure returns (bytes16) {
		bytes16 mpBA = ABDKFloat.div(ABDKFloat.fromUInt(reserve1B), ABDKFloat.fromUInt(reserve1A));
		bytes16 mpCB = ABDKFloat.div(ABDKFloat.fromUInt(reserve2C), ABDKFloat.fromUInt(reserve2B));
		bytes16 mpAC = ABDKFloat.div(ABDKFloat.fromUInt(reserve3A), ABDKFloat.fromUInt(reserve3C));
		return ABDKFloat.sub(ABDKFloat.mul(ABDKFloat.mul(mpBA, mpCB), mpAC), ABDKFloat.fromUInt(1));
	}

	function getTriTradeIterator(
		TriIteratorInputs memory inputs
	) internal view returns (uint256 input, uint256 out1in2, uint256 out2in3, uint256 output) {
		input = inputs.info1.reserveIn > INPUT_STEP_DIVISOR ? inputs.info1.reserveIn / INPUT_STEP_DIVISOR : 1000;
		out1in2 = IUniswapV2Router02(inputs.params.exchange1).getAmountOut(input, inputs.info1.reserveIn, inputs.info1.reserveOut);
		out2in3 = out1in2 > 0 ? IUniswapV2Router02(inputs.params.exchange2).getAmountOut(out1in2, inputs.info2.reserveIn, inputs.info2.reserveOut) : 0;
		output = out2in3 > 0 ? IUniswapV2Router02(inputs.params.exchange3).getAmountOut(out2in3, inputs.info3.reserveIn, inputs.info3.reserveOut) : 0;
		if (output == 0) {
			return (0, 0, 0, 0);
		}
		Iter memory iter = Iter(
			0, // iterator
			ABDKFloat.div(ABDKFloat.fromUInt(inputs.params.swapFeeSum), ABDKFloat.fromUInt(10000)), // target imbalance
			getTriImbalance(
				inputs.info1.reserveIn + input,
				inputs.info1.reserveOut - out1in2,
				inputs.info2.reserveIn + out1in2,
				inputs.info2.reserveOut - out2in3,
				inputs.info3.reserveIn + out2in3,
				inputs.info3.reserveOut - output
			) // post step imbalance
		);
		for (iter.iterator = 0; iter.iterator < MAX_ITERATIONS; iter.iterator++) {
			input = ABDKFloat.toUInt(
				ABDKFloat.mul(
					ABDKFloat.sub(inputs.initImbalance, iter.targetImbalance),
					ABDKFloat.div(ABDKFloat.fromUInt(input), ABDKFloat.sub(inputs.initImbalance, iter.postStepImbalance))
				)
			);
			out1in2 = input > 0 ? IUniswapV2Router02(inputs.params.exchange1).getAmountOut(input, inputs.info1.reserveIn, inputs.info1.reserveOut) : 0;
			out2in3 = out1in2 > 0 ? IUniswapV2Router02(inputs.params.exchange2).getAmountOut(out1in2, inputs.info2.reserveIn, inputs.info2.reserveOut) : 0;
			output = out2in3 > 0 ? IUniswapV2Router02(inputs.params.exchange3).getAmountOut(out2in3, inputs.info3.reserveIn, inputs.info3.reserveOut) : 0;
			if (output == 0) {
				return (0, 0, 0, 0);
			}
			iter.postStepImbalance = getTriImbalance(
				inputs.info1.reserveIn + input,
				inputs.info1.reserveOut - out1in2,
				inputs.info2.reserveIn + out1in2,
				inputs.info2.reserveOut - out2in3,
				inputs.info3.reserveIn + out2in3,
				inputs.info3.reserveOut - output
			);
			if (ABDKFloat.cmp(ITERATOR_THRESHOLD, ABDKFloat.abs(ABDKFloat.sub(iter.postStepImbalance, iter.targetImbalance))) == 1) {
				return (input, out1in2, out2in3, output);
			}
		}
		return (input, out1in2, out2in3, output);
	}

	function getTriOpportunity (
		TriCall memory params
	) internal view returns (TriOpportunity memory) {
		OptimalInfo memory info1 = OptimalInfo(
			params.token1, // tokenIn
			params.token2, // tokenOut
			0, // optimalInput
			0, // optimalOutput
			0, // reserveIn 
			0, // reserveOut
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange1).factory()
		);
		
		info1 = getOptimalInfo(info1);

		if(info1.reserveIn <= MIN_RESERVE || info1.reserveOut <= MIN_RESERVE){
			return TriOpportunity(
				info1.tokenIn, 
				info1.tokenOut, 
				address(0),
				info1.poolAddress, 
				address(0), 
				address(0), 
				info1.input, 
				info1.output, 
				0, 
				0
			);
		}

		OptimalInfo memory info2 = OptimalInfo(
			params.token2, // tokenIn
			params.token3, // tokenOut
			0, // input
			0, // output
			0, // reserveIn 
			0, // reserveOut
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange2).factory()
		);

		info2 = getOptimalInfo(info2);

		if(info2.reserveIn <= MIN_RESERVE || info2.reserveOut <= MIN_RESERVE){
			return TriOpportunity(
				info1.tokenIn, 
				info1.tokenOut, 
				info2.tokenOut,
				info1.poolAddress, 
				info2.poolAddress, 
				address(0), 
				info1.input, 
				info1.output, 
				info2.output, 
				0
			);
		}
		
		OptimalInfo memory info3 = OptimalInfo(
			params.token3, // tokenIn
			params.token1, // tokenOut
			0, // optimalInput
			0, // optimalOutput
			0, // reserveIn 
			0, // reserveOut
			address(0), // poolAddress
			IUniswapV2Router02(params.exchange3).factory()
		);



		info3 = getOptimalInfo(info3);

		if(info3.reserveIn <= MIN_RESERVE || info3.reserveOut <= MIN_RESERVE){
			return TriOpportunity(
				info1.tokenIn, 
				info1.tokenOut, 
				info2.tokenOut,
				info1.poolAddress, 
				info2.poolAddress, 
				info3.poolAddress, 
				info1.input, 
				info1.output, 
				info2.output, 
				0
			);
		}

		bytes16 imbalance = getTriImbalance(
			info1.reserveIn, info1.reserveOut,
			info2.reserveIn, info2.reserveOut,
			info3.reserveIn, info3.reserveOut
		);

		if (ABDKFloat.cmp(imbalance, ABDKFloat.div(ABDKFloat.fromUInt(params.swapFeeSum), ABDKFloat.fromUInt(10000))) != 1) {
			return TriOpportunity(
				info1.tokenIn, 
				info1.tokenOut, 
				info2.tokenOut,
				info1.poolAddress, 
				info2.poolAddress, 
				info3.poolAddress, 
				info1.input, 
				info1.output, 
				info2.output, 
				0
			);
		}

		(info1.input, info1.output, info2.output, info3.output) = getTriTradeIterator(TriIteratorInputs(params, imbalance, info1, info2, info3));
		
		return TriOpportunity(
			info1.tokenIn, info1.tokenOut, info2.tokenOut,
			info1.poolAddress, info2.poolAddress, info3.poolAddress, 
			info1.input, info1.output, info2.output, info3.output
		);
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
