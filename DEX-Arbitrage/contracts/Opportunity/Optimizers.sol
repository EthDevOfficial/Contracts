// pragma solidity >=0.5.0;
// // SPDX-License-Identifier: UNLICENSED
// pragma experimental ABIEncoderV2;
// import '../External/ABDKFloat.sol';
// import '../External/SafeMath.sol';
// import './Optimizer.sol';

// // the Uni optimal finders use int128 for ABDK fixed point numbers. The divisor of these is 2^64
// // the Bal optimal finders additionally use the ABDK float representation

// library Optimizers {
// 	using SafeMath for uint256;

// 	function getUniOptimalPreMP(
// 		Optimizer.OptimalInfo memory params,
// 		bytes16 swapFee
// 	) public pure returns (bytes16) {
// 		//bytes16 denom = ABDKFloat.sqrt(ABDKFloat.from64x64(params.swapFee));
// 		bytes16 rootROut = ABDKFloat.sqrt(ABDKFloat.fromUInt(params.reserveOut));
// 		bytes16 rootRIn = ABDKFloat.sqrt(ABDKFloat.fromUInt(params.reserveIn));
// 		bytes16 RInROut = ABDKFloat.mul(rootROut, rootRIn);
// 		return ABDKFloat.div(RInROut, swapFee);
// 		//return RInROut;
// 	}

// 	function getUniOutputGivenMp(
// 		bytes16 preMP,
// 		bytes16 rootMP,
// 		uint256 reserveOut
// 	) external pure returns (uint256) {
// 		//bytes16 denom = ABDKFloat.sqrt(mp);
// 		bytes16 presub = ABDKFloat.div(preMP, rootMP);
// 		uint256 sub = ABDKFloat.toUInt(presub);
// 		return reserveOut > sub ? reserveOut.sub(sub) : 0;
// 	}

// 	// function getUniOptimalPreMPOLD(Optimizer.OptimalInfo memory params) public pure returns (int128) {
// 	// 	int128 denom = ABDK.sqrt(params.swapFee);
// 	// 	int128 rootROut = ABDK.sqrt(ABDK.divu(params.reserveOut, params.portion));
// 	// 	int128 rootRIn = ABDK.sqrt(ABDK.divu(params.reserveIn, params.portion));
// 	// 	int128 RInROut = ABDK.mul(rootROut, rootRIn);
// 	// 	return ABDK.div(RInROut, denom);
// 	// }

// 	// function getUniOptimalPreMPTEST(
// 	// 	uint256 reserveIn,
// 	// 	uint256 reserveOut,
// 	// 	int128 swapFee,
// 	// 	uint256 portion
// 	// ) external pure returns (int128) {
// 	// 	int128 denom = ABDK.sqrt(swapFee);
// 	// 	int128 rootROut = ABDK.sqrt(ABDK.divu(reserveOut, portion));
// 	// 	int128 rootRIn = ABDK.sqrt(ABDK.divu(reserveIn, portion));
// 	// 	int128 RInROut = ABDK.mul(rootROut, rootRIn);
// 	// 	return ABDK.div(RInROut, denom);
// 	// }

// 	// function getUniOptimalGivenMpOLD(
// 	// 	int128 numerator,
// 	// 	int128 mp,
// 	// 	uint256 portion,
// 	// 	uint256 reserveOut
// 	// ) external pure returns (uint256) {
// 	// 	int128 denom = ABDK.sqrt(mp);
// 	// 	int128 premul = ABDK.div(numerator, denom);
// 	// 	uint256 sub = ABDK.mulu(premul, portion);
// 	// 	return reserveOut > sub ? reserveOut.sub(sub) : 0;
// 	// }

// 	// calc balOptimalPreMP = reserveIn * (1 / initSpotPrice) ^ (wOut / (wIn + wOut))
// 	// implemented as reserveIn * 2 ^ ((log2(1 / initSpotPrice)) * (wOut / (wIn + wOut))) with abdk float library (bytes16 stuff)
// 	// function getBalOptimalPreMP(optimalOpportunities.OptimalInfo memory params) public pure returns (optimalOpportunities.OptimalInfo memory) {
// 	// 	int128 initSpotPrice = calcSpotPrice(params.reserveIn, params.weightIn, params.reserveOut, params.weightOut, params.swapFee);
// 	// 	require(initSpotPrice > 0, 'Init spot price should be above 0');
// 	// 	require(params.weightOut.add(params.weightIn) > 0, 'Weight in should be above 0');
// 	// 	bytes16 exponent = ABDKFloat.from64x64(ABDK.divu(params.weightOut, params.weightOut.add(params.weightIn)));
// 	// 	bytes16 logExp = ABDKFloat.log_2(ABDKFloat.from64x64(ABDK.div(2**64, initSpotPrice)));
// 	// 	bytes16 fullExp = ABDKFloat.mul(exponent, logExp);
// 	// 	bytes16 bytesPreMP = ABDKFloat.pow_2(fullExp);
// 	// 	int128 preMulPreMP = ABDKFloat.to64x64(bytesPreMP);
// 	// 	params.optimalPreMP = ABDK.mul(ABDK.divu(params.reserveIn, params.portion), preMulPreMP);
// 	// 	return params;
// 	// }

// 	// function _getBalOptimalPreMP(
// 	// 	uint256 reserveIn,
// 	// 	uint256 weightIn,
// 	// 	uint256 reserveOut,
// 	// 	uint256 weightOut,
// 	// 	int128 swapFee,
// 	// 	uint256 portion
// 	// ) external pure returns (int128) {
// 	// 	int128 initSpotPrice = calcSpotPrice(reserveIn, weightIn, reserveOut, weightOut, swapFee);
// 	// 	bytes16 exponent = ABDKFloat.from64x64(ABDK.divu(weightOut, SafeMath.add(weightOut, weightIn)));
// 	// 	bytes16 logExp = ABDKFloat.log_2(ABDKFloat.from64x64(ABDK.div(2**64, initSpotPrice)));
// 	// 	bytes16 fullExp = ABDKFloat.mul(exponent, logExp);
// 	// 	bytes16 bytesPreMP = ABDKFloat.pow_2(fullExp);
// 	// 	int128 preMulPreMP = ABDKFloat.to64x64(bytesPreMP);
// 	// 	return ABDK.mul(ABDK.divu(reserveIn, portion), preMulPreMP);
// 	// }

// 	// optimalIn = portion * optimalPreMP * MP ^ (weightOut / (weightOut + weightIn)) - reserveIn
// 	// implemented as portion * optimalPreMP * 2 ^ (log2(MP) * (wOut / (wIn + wOut)))
// 	// function getBalOptimalGivenMp(optimalOpportunities.OptimalInfo memory info, int128 MP) public pure returns (uint256) {
// 	// 	bytes16 exponent = ABDKFloat.from64x64(ABDK.divu(info.weightOut, SafeMath.add(info.weightOut, info.weightIn)));
// 	// 	bytes16 logExp = ABDKFloat.log_2(ABDKFloat.from64x64(MP));
// 	// 	bytes16 fullExp = ABDKFloat.mul(exponent, logExp);
// 	// 	int128 mpToPow = ABDKFloat.to64x64(ABDKFloat.pow_2(fullExp));
// 	// 	uint256 opPreSub = ABDK.mulu(ABDK.mul(info.optimalPreMP, mpToPow), info.portion);
// 	// 	if (opPreSub > info.reserveIn) {
// 	// 		return opPreSub.sub(info.reserveIn);
// 	// 	} else {
// 	// 		return 0;
// 	// 	}
// 	// }

// 	// function _getBalOptimalGivenMp(
// 	// 	uint256 weightIn,
// 	// 	uint256 weightOut,
// 	// 	int128 optimalPreMP,
// 	// 	int128 oppositeMP,
// 	// 	uint256 reserveIn,
// 	// 	uint256 portion
// 	// ) external pure returns (uint256) {
// 	// 	bytes16 exponent = ABDKFloat.from64x64(ABDK.divu(weightOut, SafeMath.add(weightOut, weightIn)));
// 	// 	bytes16 logExp = ABDKFloat.log_2(ABDKFloat.from64x64(oppositeMP));
// 	// 	bytes16 fullExp = ABDKFloat.mul(exponent, logExp);
// 	// 	int128 mpToPow = ABDKFloat.to64x64(ABDKFloat.pow_2(fullExp));
// 	// 	uint256 opPreSub = ABDK.mulu(ABDK.mul(optimalPreMP, mpToPow), portion);
// 	// 	if (opPreSub > reserveIn) {
// 	// 		return opPreSub.sub(reserveIn);
// 	// 	} else {
// 	// 		return 0;
// 	// 	}
// 	// }

// 	// function bNumToAbdk(uint256 bnum) internal pure returns (int128 x) {
// 	// 	// converts the abdk fixed point representation to the balancer math representation
// 	// 	return ABDK.divu(bnum, 10**18);
// 	// }

// 	// function calcSpotPrice(
// 	// 	uint256 tokenBalanceIn,
// 	// 	uint256 tokenWeightIn,
// 	// 	uint256 tokenBalanceOut,
// 	// 	uint256 tokenWeightOut,
// 	// 	int128 swapFee
// 	// ) public pure returns (int128 spotPrice) {
// 	// 	int128 numer = ABDK.divu(tokenBalanceIn, tokenWeightIn);
// 	// 	int128 denom = ABDK.divu(tokenBalanceOut, tokenWeightOut);
// 	// 	int128 ratio = ABDK.div(numer, denom);
// 	// 	int128 scale = ABDK.div(2**64, ABDK.sub(2**64, swapFee));
// 	// 	return ABDK.mul(ratio, scale);
// 	// }
// }
