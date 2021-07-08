pragma solidity >=0.5.0;


interface IDXSwapRouter  {
    function factory() external pure returns (address);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountIn);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint swapFee) external pure returns (uint amountOut);
    function getSwapFee(address factory, address tokenA, address tokenB) external view returns (uint32);
}

interface IDXswapCallee {
    function DXswapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}