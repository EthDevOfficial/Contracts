pragma solidity >=0.5.0;
// SPDX-License-Identifier: UNLICENSED
pragma experimental ABIEncoderV2;
import '../External/SafeMath.sol';
import '../External/ABDK.sol';

library ArbEx {
  using SafeMath for uint256;

  // need to set up addresses to store pool reserves, and functions to return the current reserve amounts
  // then we can check for ops with our reserves, and add to execution contract

  function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut) {
		require(amountIn > 0, 'ArbExLibrary: INSUFFICIENT_INPUT_AMOUNT');
		require(reserveIn > 0 && reserveOut > 0, 'ArbExLibrary: INSUFFICIENT_LIQUIDITY');
		uint256 _amountIn = amountIn.mul(1000); // 
		uint256 numerator = _amountIn.mul(reserveOut);
		uint256 denominator = reserveIn.mul(1000).add(_amountIn);
		require(denominator > 0);
		amountOut = numerator / denominator;
	}

  function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn) {
		require(amountOut > 0, 'ArbExLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
		require(reserveIn > 0 && reserveOut > 0, 'ArbExLibrary: INSUFFICIENT_LIQUIDITY');
		uint256 numerator = reserveIn.mul(amountOut).mul(1000);
		uint256 denominator = reserveOut.sub(amountOut).mul(1000);
		require(denominator > 0);
		amountIn = (numerator / denominator).add(1);
	}

  function opOutPreMP(
    uint256 reserveIn,
    uint256 reserveOut,
    uint256 portion
  ) external pure returns (int128) {
    int128 rootROut = ABDK.sqrt(ABDK.divu(reserveOut, portion));
    int128 rootRIn = ABDK.sqrt(ABDK.divu(reserveIn, portion));
    int128 opPreMP = ABDK.mul(rootROut, rootRIn);
    return opPreMP;
  }

  function getMP(uint256 reserveIn, uint256 reserveOut) external pure returns (int128) {
		require(reserveOut > 0 && reserveIn > 0);
		return ABDK.divu(reserveIn, reserveOut);
	}

  function getOpOutGivenMP(
    int128 preMP,
    int128 mp,
    uint256 portion,
    uint256 reserveOut
  ) external pure returns (uint256) {
    int128 denom = ABDK.sqrt(mp);
    int128 premul = ABDK.div(preMP, denom);
    uint256 sub = ABDK.mulu(premul, portion);
    return reserveOut > sub ? reserveOut.sub(sub) : 0;
  }
}
