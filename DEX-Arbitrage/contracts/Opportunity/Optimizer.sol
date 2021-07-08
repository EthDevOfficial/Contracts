// pragma solidity >=0.6.0;
// // SPDX-License-Identifier: UNLICENSED
// pragma experimental ABIEncoderV2;
// import '../External/Uniswap.sol';
// import './Optimizers.sol';
// import '../External/Balancer.sol';

// contract Optimizer {
// 	address UniswapFactoryAddress; //For converting to std
// 	address owner;
// 	bytes16 UNI_TRI_SWAP_FEE;
// 	bytes16 UNI_SIMPLE_SWAP_FEE;

// 	struct SimpleCall {
// 		address outerToken;
// 		address innerToken;
// 		uint8 exchange1;
// 		uint8 exchange2;
// 		address factory1;
// 		address factory2;
// 	}

// 	struct TriCall {
// 		address token1;
// 		address token2;
// 		address token3;
// 		uint8 exchange1;
// 		uint8 exchange2;
// 		uint8 exchange3;
// 		address factory1;
// 		address factory2;
// 		address factory3;
// 	}

// 	struct Opportunity {
// 		address outerToken;
// 		address innerToken;
// 		uint256 reserve1;
// 		uint256 reserve2;
// 		address awayPool;
// 		address returnPool;
// 		uint256 inputWei;
// 		uint256 innerWei;
// 		uint256 outputWei;
// 		uint256 diff;
// 		uint256 stdDiff;
// 		bool ignore;
// 		bool failed;
// 	}

// 	struct TriOpportunity {
// 		address token1;
// 		address token2;
// 		address token3;
// 		uint256 reserve1;
// 		uint256 reserve2;
// 		uint256 reserve3;
// 		address pool1;
// 		address pool2;
// 		address pool3;
// 		uint256 input1;
// 		uint256 output1; // == input2
// 		uint256 output2; // == input 3
// 		uint256 output3;
// 		uint256 diff;
// 		uint256 stdDiff;
// 		bool ignore;
// 		bool failed;
// 	}

// 	struct OptimalInfo {
// 		address tokenIn;
// 		address tokenOut;
// 		uint256 optimalInput;
// 		uint256 optimalOutput;
// 		uint256 reserveIn;
// 		uint256 reserveOut;
// 		uint256 reserve0;
// 		uint256 weightIn; // balancer weights if on balancer
// 		uint256 weightOut;
// 		bytes16 preMP;
// 		//bytes16 MP;
// 		bytes16 rootMP; // need to add
// 		//bytes16 swapFee;
// 		//bytes16 rootSwapFee;
// 		uint8 exchange;
// 		address poolAddress;
// 		address factory;
// 		bool ignore;
// 		bool failed;
// 		//uint256 portion;
// 	}

// 	//Create modifier to limit who can call the contract
// 	modifier onlyOwner() {
// 		require(msg.sender == owner, 'Sender not authorized.');
// 		// Do not forget the "_;"! It will
// 		// be replaced by the actual function
// 		// body when the modifier is used.
// 		_;
// 	}

// 	constructor(address uniswapFactory) {
// 		UniswapFactoryAddress = uniswapFactory;
// 		owner = msg.sender;
// 		UNI_SIMPLE_SWAP_FEE = ABDKFloat.sqrt(ABDKFloat.div(ABDKFloat.fromUInt(9955), ABDKFloat.fromUInt(10000)));
// 		UNI_TRI_SWAP_FEE = ABDKFloat.div(ABDKFloat.fromUInt(9934), ABDKFloat.fromUInt(10000));
// 	}

// 	//Change the contract owner
// 	function changeOwner(address payable newOwner) external onlyOwner {
// 		owner = newOwner;
// 	}

// 	//Change the router address
// 	function changeUniswapFactory(address newAddress) external onlyOwner {
// 		UniswapFactoryAddress = newAddress;
// 	}

// 	function updateSwapFee(uint256 simpleFee, uint256 triFee) external onlyOwner {
// 		UNI_SIMPLE_SWAP_FEE = ABDKFloat.sqrt(ABDKFloat.div(ABDKFloat.fromUInt(simpleFee), ABDKFloat.fromUInt(10000)));
// 		UNI_TRI_SWAP_FEE = ABDKFloat.div(ABDKFloat.fromUInt(triFee), ABDKFloat.fromUInt(10000));
// 	}

// 	function simpleMulticall(bytes[] calldata calls, address stdToken) external view returns (bytes[] memory ret) {
//     ret = new bytes[](calls.length);
//     for (uint i = 0; i < calls.length; i++) {
//       ret[i] = getOpportunityFromCall(calls[i], stdToken);
//     }
//   }

// 	function triMulticall(bytes[] calldata calls, address stdToken) external view returns (bytes[] memory ret) {
// 		ret = new bytes[](calls.length);
//     for (uint i = 0; i < calls.length; i++) {
//       ret[i] = getTriOpportunityFromCall(calls[i], stdToken);
//     }
//   }

// 	function getOpportunityFromCall(
// 		bytes memory call,
// 		address stdToken
// 		//uint256 portion
// 	) internal view returns (bytes memory) {
// 		SimpleCall memory params = abi.decode(call, (SimpleCall));
// 		return abi.encode(getOpportunity(params, stdToken));
// 	}

// 	function getTriOpportunityFromCall(
// 		bytes memory call,
// 		address stdToken
// 		//uint256 portion
// 	) internal view returns (bytes memory) {
// 		TriCall memory params = abi.decode(call, (TriCall));
// 		return abi.encode(getTriOpportunity(params, stdToken));
// 	}

// 	function makeNewOpInfo(address tokenIn, address tokenOut, uint8 exchange, address factory) internal view returns (OptimalInfo memory) {
// 		return OptimalInfo(
// 			tokenIn, // tokenIn
// 			tokenOut, // tokenOut
// 			0, // optimalInput
// 			0, // optimalOutput
// 			0, // reserveIn 
// 			0, // reserveOut
// 			0, // reserve0
// 			0, // weightIn
// 			0, // weightOut
// 			bytes16(0), // preMP
// 			//bytes16(0), // MP
// 			bytes16(0),// rootMP
// 			//bytes16(0), // swapFee
// 			//bytes16(0), // rootSwapFee
// 			exchange, // exchange
// 			address(0), // poolAddress
// 			factory, // factory
// 			false, // ignore
// 			false // failed
// 		);
// 	}

// 	function getOpportunity(
// 		SimpleCall memory params,
// 		address stdToken
// 		//uint256 portion
// 	) internal view returns (Opportunity memory) {
// 		OptimalInfo memory awayInfo = makeNewOpInfo(params.outerToken, params.innerToken, params.exchange1, params.factory1);
// 		OptimalInfo memory returnInfo = makeNewOpInfo(params.innerToken, params.outerToken, params.exchange2, params.factory2);
// 		awayInfo = getAlmostAllOptimalInfo(awayInfo, false);
// 		returnInfo = getAlmostAllOptimalInfo(returnInfo, false);
// 		bool ignore = false;
// 		if (!awayInfo.ignore && !returnInfo.ignore) {
// 			// 	Multiplying optimal away output by return mp, multiplying optimal return output by away mp
// 			awayInfo = getInputOutputByExchange(awayInfo, returnInfo);
// 			returnInfo = getInputOutputByExchange(returnInfo, awayInfo);
// 			if (!awayInfo.ignore && !returnInfo.ignore) {
// 				if (awayInfo.optimalOutput <= returnInfo.optimalInput) {
// 					// recalc return using away's output as input
// 					returnInfo.optimalOutput = getOutputFromInputByExchange(awayInfo.optimalOutput, returnInfo);
// 				} else {
// 					// recalc away using return's input as output
// 					awayInfo.optimalInput = getInputFromOutputByExchange(returnInfo.optimalInput, awayInfo);
// 					awayInfo.optimalOutput = returnInfo.optimalInput;
// 				}
// 			} else {
// 				ignore = true;
// 			}
// 		} else {
// 			ignore = true;
// 		}
// 		ignore = ignore || returnInfo.optimalOutput <= awayInfo.optimalInput;
// 		bool failed = awayInfo.failed || returnInfo.failed;
// 		Opportunity memory unstandardizedOpp = Opportunity(awayInfo.tokenIn, awayInfo.tokenOut, awayInfo.reserve0, returnInfo.reserve0, awayInfo.poolAddress, returnInfo.poolAddress, awayInfo.optimalInput, awayInfo.optimalOutput, returnInfo.optimalOutput, !ignore ? returnInfo.optimalOutput - awayInfo.optimalInput : 0, 0, ignore, failed);
// 		return ignore ? unstandardizedOpp : standardize(unstandardizedOpp, stdToken);
// 	}

// 	function getTriOpportunity (
// 		TriCall memory params,
// 		address stdToken
// 		//uint256 portion
// 	) internal view returns (TriOpportunity memory) {
// 		OptimalInfo memory info1 = makeNewOpInfo(params.token1, params.token2, params.exchange1, params.factory1);
// 		OptimalInfo memory info2 = makeNewOpInfo(params.token2, params.token3, params.exchange2, params.factory2);
// 		OptimalInfo memory info3 = makeNewOpInfo(params.token3, params.token1, params.exchange3, params.factory3);
// 		info1 = getAlmostAllOptimalInfo(info1, true);
// 		info2 = getAlmostAllOptimalInfo(info2, true);
// 		info3 = getAlmostAllOptimalInfo(info3, true);
// 		bool ignore = false;
// 		if (!info1.ignore && !info2.ignore && !info3.ignore) {
// 			info1 = getTriInputOutputByExchange(info1, info2, info3);
// 			info2 = getTriInputOutputByExchange(info2, info3, info1);
// 			info3 = getTriInputOutputByExchange(info3, info1, info2);
// 			if (!info1.ignore && !info2.ignore && !info3.ignore) {
// 				if (info1.optimalOutput <= info2.optimalInput) {
// 					info2.optimalOutput = getOutputFromInputByExchange(info1.optimalOutput, info2);
// 					if (info2.optimalOutput <= info3.optimalInput) {
// 						info3.optimalOutput = getOutputFromInputByExchange(info2.optimalOutput, info3);
// 					} else {
// 						info2.optimalOutput = info3.optimalInput;
// 						info1.optimalOutput = getInputFromOutputByExchange(info2.optimalOutput, info2); // info2.optimalInput = info1.optimalOutput
// 						info1.optimalInput = getInputFromOutputByExchange(info1.optimalOutput, info1);
// 					}
// 				} else {
// 					if (info2.optimalOutput <= info3.optimalInput) {
// 						info3.optimalOutput = getOutputFromInputByExchange(info2.optimalOutput, info3);
// 						info1.optimalInput = getInputFromOutputByExchange(info2.optimalInput, info1);
// 						info1.optimalOutput = info2.optimalInput;
// 					} else {
// 						info2.optimalOutput = info3.optimalInput;
// 						info1.optimalOutput = getInputFromOutputByExchange(info2.optimalOutput, info2);
// 						info1.optimalInput = getInputFromOutputByExchange(info1.optimalOutput, info1);
// 					}					
// 				}
// 			} else {
// 				ignore = true;
// 			}
// 		} else {
// 			ignore = true;
// 		}
// 		ignore = ignore || info3.optimalOutput <= info1.optimalInput;
// 		bool failed = info1.failed || info2.failed || info3.failed;
// 		TriOpportunity memory unstandardizedOpp = TriOpportunity(
// 			info1.tokenIn, info1.tokenOut, info2.tokenOut, info1.reserve0, info2.reserve0, info3.reserve0,
// 			info1.poolAddress, info2.poolAddress, info3.poolAddress, 
// 			info1.optimalInput, info1.optimalOutput, info2.optimalOutput, info3.optimalOutput, 
// 			!ignore ? info3.optimalOutput - info1.optimalInput : 0, 0, ignore, failed
// 		);
// 		return ignore ? unstandardizedOpp : triStandardize(unstandardizedOpp, stdToken);
// 	}

// 	function standardize(Opportunity memory unstandardizedOpp, address stdToken) internal view returns (Opportunity memory standardizedOpp) {
// 		if (unstandardizedOpp.outerToken != stdToken) {
// 			try Uniswap.getReserves(unstandardizedOpp.outerToken, stdToken, UniswapFactoryAddress) returns (uint256 reserveIn, uint256 reserveOut, bool reserve0IsIn, address poolAddress) {
// 				if (reserveIn > 0) {
// 					unstandardizedOpp.stdDiff = ABDK.mulu(ABDK.divu(reserveOut, reserveIn), unstandardizedOpp.diff);
// 				}
// 			} catch {
// 				unstandardizedOpp.failed = true;
// 				unstandardizedOpp.ignore = true;
// 			}
// 		} else {
// 			unstandardizedOpp.stdDiff = unstandardizedOpp.diff;
// 		}
// 		return unstandardizedOpp;
// 	}

// 	function triStandardize(TriOpportunity memory unstandardizedOpp, address stdToken) internal view returns (TriOpportunity memory standardizedOpp) {
// 		if (unstandardizedOpp.token1 != stdToken) {
// 			try Uniswap.getReserves(unstandardizedOpp.token1, stdToken, UniswapFactoryAddress) returns (uint256 reserveIn, uint256 reserveOut, bool reserve0IsIn, address poolAddress) {
// 				if (reserveIn > 0) {
// 					unstandardizedOpp.stdDiff = ABDK.mulu(ABDK.divu(reserveOut, reserveIn), unstandardizedOpp.diff);
// 				}
// 			} catch {
// 				unstandardizedOpp.failed = true;
// 				unstandardizedOpp.ignore = true;
// 			}
// 		} else {
// 			unstandardizedOpp.stdDiff = unstandardizedOpp.diff;
// 		}
// 		return unstandardizedOpp;
// 	}

// 	function getAlmostAllOptimalInfo(OptimalInfo memory info, bool isTri) internal view returns (OptimalInfo memory optimalInfo) {
// 		if (info.exchange == 0) {
// 			try Uniswap.getReserves(info.tokenIn, info.tokenOut, info.factory) returns (uint256 reserveIn, uint256 reserveOut, bool reserve0IsIn, address poolAddress) {
// 				(info.reserveIn, info.reserveOut, info.poolAddress) = (reserveIn, reserveOut, poolAddress);
// 				//info.swapFee = ABDKFloat.from64x64(18391404000000000000);
// 				info.reserve0 = reserve0IsIn ? reserveIn : reserveOut;
// 				info.preMP = Optimizers.getUniOptimalPreMP(info, isTri ? UNI_TRI_SWAP_FEE : UNI_SIMPLE_SWAP_FEE);
// 				info = getMPByExchange(info);
// 			} catch {
// 				info.ignore = true;
// 				info.failed = true;
// 			}
// 		} else {
// 			// try Balancer.getPoolInfo(info.tokenIn, info.tokenOut, info.proxy) returns (address poolAddress, uint256 tokenBalanceIn, uint256 tokenBalanceOut, uint256 tokenWeightIn, uint256 tokenWeightOut, uint256 swapFee) {
// 			// 	(info.reserveIn, info.reserveOut, info.poolAddress, info.weightIn) = (tokenBalanceIn, tokenBalanceOut, poolAddress, tokenWeightIn);
// 			// 	info.weightOut = tokenWeightOut;
// 			// 	info.swapFee = Optimizers.bNumToAbdk(swapFee);
// 			// 	try Optimizers.getBalOptimalPreMP(info) returns (OptimalInfo memory newInfo) {
// 			// 		info = getMPByExchange(newInfo);
// 			// 	} catch {
// 			// 		info.ignore = true;
// 			// 	}
// 			// } catch {
// 			// 	info.ignore = true;
// 			// 	info.failed = true;
// 			// }
// 		}
// 		return info;
// 	}

// 	function getMPByExchange(OptimalInfo memory params) internal view returns (OptimalInfo memory optimalInfo) {
// 		if (params.exchange == 0) {
// 			try Uniswap.getMP(params.reserveOut, params.reserveIn) returns (bytes16 MP) {
// 				params.rootMP = ABDKFloat.sqrt(MP);
// 			} catch {
// 				params.ignore = true;
// 				params.failed = true;
// 			}
// 		} else {
// 			// try Optimizers.calcSpotPrice(params.reserveOut, params.weightOut, params.reserveIn, params.weightIn, params.swapFee) returns (int128 MP) {
// 			// 	params.MP = MP;
// 			// } catch {
// 			// 	params.ignore = true;
// 			// }
// 		}
// 		return params;
// 	}

// 	function getInputOutputByExchange(OptimalInfo memory info, OptimalInfo memory oppositeInfo) internal view returns (OptimalInfo memory optimalInfo) {
// 		if (info.exchange == 0) {
// 			info.optimalOutput = Optimizers.getUniOutputGivenMp(info.preMP, oppositeInfo.rootMP, info.reserveOut);
// 			if (info.optimalOutput > 0) {
// 				try Uniswap.getAmountIn(info.optimalOutput, info.reserveIn, info.reserveOut) returns (uint256 optimalInput) {
// 					info.optimalInput = optimalInput;
// 				} catch {
// 					info.ignore = true;
// 					info.failed = true;
// 				}
// 			} else {
// 				info.ignore = true;
// 			}
// 		} else {
// 			// info.optimalInput = Optimizers.getBalOptimalGivenMp(info, oppositeInfo.MP);
// 			// if (info.optimalInput > 0) {
// 			// 	try Balancer.getAmountOut(info.poolAddress, info.tokenIn, info.tokenOut, info.optimalInput) returns (uint256 optimalOutput) {
// 			// 		info.optimalOutput = optimalOutput;
// 			// 	} catch {
// 			// 		info.ignore = true;
// 			// 	}
// 			// } else {
// 			// 	info.ignore = true;
// 			// }
// 		}
// 		return info;
// 	}

// 	function getTriInputOutputByExchange(OptimalInfo memory info, OptimalInfo memory oppositeInfo1, OptimalInfo memory oppositeInfo2) internal view returns (OptimalInfo memory optimalInfo) {
// 		if (info.exchange == 0) {
// 			info.optimalOutput = Optimizers.getUniOutputGivenMp(info.preMP, ABDKFloat.mul(oppositeInfo1.rootMP, oppositeInfo2.rootMP), info.reserveOut);
// 			if (info.optimalOutput > 0) {
// 				try Uniswap.getAmountIn(info.optimalOutput, info.reserveIn, info.reserveOut) returns (uint256 optimalInput) {
// 					info.optimalInput = optimalInput;
// 				} catch {
// 					info.ignore = true;
// 					info.failed = true;
// 				}
// 			} else {
// 				info.ignore = true;
// 			}
// 		} else {
// 			// info.optimalInput = Optimizers.getBalOptimalGivenMp(info, ABDK.mul(oppositeInfo1.MP, oppositeInfo2.MP));
// 			// if (info.optimalInput > 0) {
// 			// 	try Balancer.getAmountOut(info.poolAddress, info.tokenIn, info.tokenOut, info.optimalInput) returns (uint256 optimalOutput) {
// 			// 		info.optimalOutput = optimalOutput;
// 			// 	} catch {
// 			// 		info.ignore = true;
// 			// 	}
// 			// } else {
// 			// 	info.ignore = true;
// 			// }
// 		}
// 		return info;
// 	}

// 	function getInputFromOutputByExchange(uint256 output, OptimalInfo memory awayInfo) internal view returns (uint256) {
// 		if (output > 0) {
// 			if (awayInfo.exchange == 0) {
// 				try Uniswap.getAmountIn(output, awayInfo.reserveIn, awayInfo.reserveOut) returns (uint256 input) {
// 					return input;
// 				} catch {
// 					awayInfo.failed = true;
// 				}
// 			} else {
// 				try Balancer.getAmountIn(awayInfo.poolAddress, awayInfo.tokenIn, awayInfo.tokenOut, output) returns (uint256 input) {
// 					return input;
// 				} catch {
// 					awayInfo.failed = true;
// 				}
// 			}
// 		}
// 		return 0;
// 	}

// 	function getOutputFromInputByExchange(uint256 input, OptimalInfo memory returnInfo) internal view returns (uint256) {
// 		if (input > 0) {
// 			if (returnInfo.exchange == 0) {
// 				try Uniswap.getAmountOut(input, returnInfo.reserveIn, returnInfo.reserveOut) returns (uint256 output) {
// 					return output;
// 				} catch {
// 					returnInfo.failed = true;
// 				}
// 			} else {
// 				try Balancer.getAmountOut(returnInfo.poolAddress, returnInfo.tokenIn, returnInfo.tokenOut, input) returns (uint256 output) {
// 					return output;
// 				} catch {
// 					returnInfo.failed = true;
// 				}
// 			}
// 		}
// 		return 0;
// 	}
// }
