// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '../interfaces/IPoolWrapper.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

/**
 @title
 @notice
*/
contract Mainnet_UniswapV2 is IPoolWrapper {
  function getQuote(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut, address _pool) {
    _pool = _computePairAddressUniV2(_tokenIn, _tokenOut);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_pool).getReserves();

    // reserve0 is the one for tokenIn
    (reserve0, reserve1) = _tokenIn < _tokenOut ? (reserve0, reserve1) : (reserve1, reserve0);

    _amountOut = _computeAmountOutWithFee(_amountIn, reserve0, reserve1);
  }

  // _minOut already taking slippage into account (same for every pool, in the allocator itself)
  // will revert 'K' if hit in pool.swap
  function swap(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut,
    uint256 _minOut,
    address _pool
  ) external {
    IERC20(_tokenIn).transfer(_pool, _amountIn);

    (uint256 amount0Out, uint256 amount1Out) = _tokenIn < _tokenOut
      ? (_amountIn, _minOut)
      : (_minOut, _amountIn);

    IUniswapV2Pool(_pool).swap(amount0Out, amount1Out, msg.sender, new bytes(0));
  }

  function _computePairAddressUniV2(address _token0, address _token1)
    internal
    pure
    returns (address pair)
  {
    (_token0, _token1) = _token0 < _token1 ? (_token0, _token1) : (_token1, _token0);

    bytes32 pubKey = keccak256(
      abi.encodePacked(
        hex'ff',
        address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // UniV2 Factory
        keccak256(abi.encodePacked(_token0, _token1)),
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
      )
    );

    pair = address(bytes20(pubKey));
  }

  function _computeAmountOutWithFee(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    uint256 amountInWithFee = amountIn * (997);
    uint256 numerator = amountInWithFee * (reserveOut);
    uint256 denominator = reserveIn * (1000) + (amountInWithFee);
    amountOut = numerator / denominator;
  }
}
