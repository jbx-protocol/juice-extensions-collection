//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

// @dev Pool generic wrapper
interface IPoolWrapper {
  function getQuote(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut, address _pool);

  function swap(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountOut,
    address _pool
  ) external payable returns (uint256 _amountReceived);
}
