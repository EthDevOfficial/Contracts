pragma solidity >=0.5.0;
import "./ABDKFloat.sol";
import "./SafeMath.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IUniswapV2Pair {
	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves()
        external
        view
        returns (
            uint112 reserveIn,
            uint112 reserveOut,
            uint32 blockTimestampLast
        );
}

interface IUniswapV2Factory {
    function getPair(address tokenIn, address tokenOut)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
}

