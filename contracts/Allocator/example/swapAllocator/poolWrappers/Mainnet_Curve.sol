// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/ICurveRegistry.sol';
import '../interfaces/ICurvePool.sol';
import '../interfaces/IPoolWrapper.sol';

/**
 @title
 @notice
*/
contract Mainnet_curve is IPoolWrapper {
  // Same on every chain
  address constant addressProvider = 0x0000000022D53366457F9d5E68Ec105046FC4383;

  // Pools registry, fetched via addressProvider
  address immutable registry;

  constructor() {
    // Find the registryProvider address and store it
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
    // Find the pool for the assets
    _pool = ICurveRegistry(registry).find_pool_for_coins(_tokenIn, _tokenOut, 0);

    // No pool for tokens?
    if (_pool == address(0)) {
      _amountOut = 0;
    }
    else {  
      // Get the token indices within the Curve pool
      (int128 fromIndex, int128 toIndex, ) = ICurveRegistry(registry).get_coin_indices(
        _pool,
        _tokenIn,
        _tokenOut
      );

      // Get a quote (ie dy for a given dx)
      _amountOut = ICurvePool(_pool).get_dy(fromIndex, toIndex, _amountIn);
    }
  }

  function swap(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountOut,
    address _pool
  ) external {
    // Get the token indicex in the pool
    (int128 i, int128 j, ) = ICurveRegistry(registry).get_coin_indices(_pool, _tokenIn, _tokenOut);

    // Approve the swapped token
    IERC20(_tokenIn).approve(_pool, _amountIn);

    // Swap - no slippage allowed, as the quote and swap are atomic
    ICurvePool(_pool).exchange(i, j, _amountIn, _amountOut);

    // Send the token received (slippage is controlled by the curve pool)
    IERC20(_tokenOut).transfer(msg.sender, IERC20(_tokenOut).balanceOf(address(this)));
  }
}
