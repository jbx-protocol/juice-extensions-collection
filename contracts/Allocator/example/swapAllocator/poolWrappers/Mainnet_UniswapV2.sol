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
    _amountOut = _computeAmountOutWithFee(_amountIn, reserve0, reserve1);
  }

  function _computePairAddressUniV2(address _token0, address _token1)
    internal
    pure
    returns (address pair)
  {
    (_token0, _token1) = MultiOracleLib.sortPairs(_token0, _token1);

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
