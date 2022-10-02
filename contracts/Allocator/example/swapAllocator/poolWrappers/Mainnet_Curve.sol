// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '../interfaces/ICurveRegistry.sol';
import '../interfaces/ICurvePool.sol';
import '../interfaces/IPoolWrapper.sol';

/**
 @title
 @notice
*/
contract Mainnet_curve is IPoolWrapper {
  address constant addressProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;
  address immutable registry;

  constructor() {
    (bool succ, bytes memory _registry) = addressProvider.call(
      abi.encodeWithSignature('function get_registry()(address)')
    );
    assert(succ);
    registry = abi.decode(_registry, (address));
  }

  function getQuote(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut, address _pool) {
    _pool = ICurveRegistry(registry).find_pool_for_coins(_tokenIn, _tokenOut, 0);
    (int128 fromIndex, int128 toIndex, ) = ICurveRegistry(registry).get_coin_indices(
      _pool,
      _tokenIn,
      _tokenOut
    );
    _amountOut = ICurvePool(_pool).get_dy(fromIndex, toIndex, _amountIn);
  }

  function swap(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut,
    uint256 _minOut,
    address _pool
  ) external {
    (int128 i, int128 j, ) = ICurveRegistry(registry).get_coin_indices(_pool, _tokenIn, _tokenOut);
    ICurvePool(_pool).exchange(i, j, _amountIn, _minOut);
  }
}
