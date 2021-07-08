pragma experimental ABIEncoderV2;
import './ABDK.sol';
pragma solidity >=0.5.0;

interface PoolInterface {
	function getDenormalizedWeight(address) external view returns (uint256);

	function getBalance(address) external view returns (uint256);

	function getSwapFee() external view returns (uint256);

	function calcOutGivenIn(
		uint256 tokenBalanceIn,
		uint256 tokenWeightIn,
		uint256 tokenBalanceOut,
		uint256 tokenWeightOut,
		uint256 tokenAmountIn,
		uint256 swapFee
	) external pure returns (uint256 tokenAmountOut);

	function calcInGivenOut(
		uint256 tokenBalanceIn,
		uint256 tokenWeightIn,
		uint256 tokenBalanceOut,
		uint256 tokenWeightOut,
		uint256 tokenAmountOut,
		uint256 swapFee
	) external pure returns (uint256 tokenAmountIn);
}

interface IBalancerRegistry {
	function getBestPoolsWithLimit(
		address tokenIn,
		address tokenOut,
		uint256 limit
	) external view returns (address[] memory pools);
}

library Balancer {
	struct Swap {
		address pool;
		address tokenIn;
		address tokenOut;
		uint256 swapAmount; // tokenInAmount / tokenOutAmount
		uint256 limitReturnAmount; // minAmountOut / maxAmountIn
		uint256 maxPrice;
	}
	struct Pool {
		address pool;
		uint256 tokenBalanceIn;
		uint256 tokenWeightIn;
		uint256 tokenBalanceOut;
		uint256 tokenWeightOut;
		uint256 swapFee;
	}

	function getAmountOut(
		address poolAddress,
		address tokenIn,
		address tokenOut,
		uint256 tokenAmountIn
	) external view returns (uint256 tokenAmountOut) {
		uint256 tokenBalanceIn = PoolInterface(poolAddress).getBalance(tokenIn);
		uint256 tokenBalanceOut = PoolInterface(poolAddress).getBalance(tokenOut);
		uint256 tokenWeightIn = PoolInterface(poolAddress).getDenormalizedWeight(tokenIn);
		uint256 tokenWeightOut = PoolInterface(poolAddress).getDenormalizedWeight(tokenOut);
		uint256 swapFee = PoolInterface(poolAddress).getSwapFee();
		return PoolInterface(poolAddress).calcOutGivenIn(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountIn, swapFee);
	}

	function getAmountIn(
		address poolAddress,
		address tokenIn,
		address tokenOut,
		uint256 tokenAmountOut
	) external view returns (uint256 tokenAmountIn) {
		uint256 tokenBalanceIn = PoolInterface(poolAddress).getBalance(tokenIn);
		uint256 tokenBalanceOut = PoolInterface(poolAddress).getBalance(tokenOut);
		uint256 tokenWeightIn = PoolInterface(poolAddress).getDenormalizedWeight(tokenIn);
		uint256 tokenWeightOut = PoolInterface(poolAddress).getDenormalizedWeight(tokenOut);
		uint256 swapFee = PoolInterface(poolAddress).getSwapFee();
		return PoolInterface(poolAddress).calcInGivenOut(tokenBalanceIn, tokenWeightIn, tokenBalanceOut, tokenWeightOut, tokenAmountOut, swapFee);
	}

	function getPoolInfo(
		address tokenIn,
		address tokenOut,
		address balancerRegistryAddress
	)
		external
		view
		returns (
			address poolAddress,
			uint256 tokenBalanceIn,
			uint256 tokenBalanceOut,
			uint256 tokenWeightIn,
			uint256 tokenWeightOut,
			uint256 swapFee
		)
	{
		try IBalancerRegistry(balancerRegistryAddress).getBestPoolsWithLimit(tokenIn, tokenOut, 1) returns (address[] memory poolAddresses) {
			require(poolAddresses.length > 0);

			poolAddress = poolAddresses[0];
			tokenBalanceIn = PoolInterface(poolAddress).getBalance(tokenIn);
			tokenBalanceOut = PoolInterface(poolAddress).getBalance(tokenOut);
			tokenWeightIn = PoolInterface(poolAddress).getDenormalizedWeight(tokenIn);
			tokenWeightOut = PoolInterface(poolAddress).getDenormalizedWeight(tokenOut);
			swapFee = PoolInterface(poolAddress).getSwapFee();

			require(tokenBalanceIn > 100000 && tokenBalanceOut > 100000 && tokenWeightIn > 10000 && tokenWeightOut > 10000 && swapFee > 0);
			return (poolAddress, tokenBalanceIn, tokenBalanceOut, tokenWeightIn, tokenWeightOut, swapFee);
		} catch {
			require(1 == 0);
		}
	}
}
