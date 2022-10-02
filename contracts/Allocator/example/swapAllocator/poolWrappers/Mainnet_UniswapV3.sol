// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';
import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import '@uniswap/v3-core/contracts/libraries/FullMath.sol';

/**
 @title
 Juicebox split allocator - swap to another asset

 @notice
*/
contract SwapAllocator {
  //@inheritdoc IJBAllocator
  function quote() external payable {
    // // UniV3
    // (address _token0, address _token1) = MultiOracleLib.sortPairs(_tokenIn, _tokenOut);
    // uint24 _fee = governanceDecidedFee[_token0][_token1] != 0
    //   ? governanceDecidedFee[_token0][_token1]
    //   : defaultFee;
    // address _pair = PoolAddress.computeAddress(
    //   address(0x1F98431c8aD98523631AE4a59f267346ea31F984), // UniV3 Factory
    //   PoolAddress.getPoolKey(_token0, _token1, _fee)
    // );
    // (uint160 _sqrtPriceX96, , , , , , ) = IUniswapV3Pool(_pair).slot0();
    // // Return amount out with "not so bad" precision (if not overflowing) : TODO: replace by uniV3 lib (there must be one)
    // if (_sqrtPriceX96 <= type(uint128).max) {
    //   uint256 ratioX192 = uint256(_sqrtPriceX96) * _sqrtPriceX96;
    //   _twapAmountOut = _tokenIn < _tokenOut
    //     ? FullMath.mulDiv(ratioX192, _amountIn, 1 << 192)
    //     : FullMath.mulDiv(1 << 192, _amountIn, ratioX192);
    // } else {
    //   uint256 ratioX128 = FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, 1 << 64);
    //   _twapAmountOut = _tokenIn < _tokenOut
    //     ? FullMath.mulDiv(ratioX128, _amountIn, 1 << 128)
    //     : FullMath.mulDiv(1 << 128, _amountIn, ratioX128);
    // }
    // Compare and swap accordingly
  }
}
