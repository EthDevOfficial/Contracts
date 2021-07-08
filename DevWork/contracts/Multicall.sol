pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

/// Multicall - Aggregate results from multiple read-only function calls
interface IUniswapV2Pair {
	function getReserves()
		external
		view
		returns (
			uint112 reserveIn,
			uint112 reserveOut,
			uint32 blockTimestampLast
		);
}

contract Multicall {
    struct ReturnObj {
        uint reserve0;
        uint reserve1;
    }

    function aggregate(address[] memory calls) public view returns (ReturnObj[] memory returnData) {
        returnData = new ReturnObj[](calls.length);
        for(uint256 i = 0; i < calls.length; i++) {
            (uint _reserve0, uint _reserve1,) = IUniswapV2Pair(calls[i]).getReserves();
            returnData[i] = ReturnObj(_reserve0, _reserve1);
        }
    }
    function getUniReserves(address pool) public view returns (uint112 _reserve0, uint112 _reserve1) {
            (_reserve0, _reserve1,) = IUniswapV2Pair(pool).getReserves();
    }
}