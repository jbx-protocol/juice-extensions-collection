// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol';

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

  address immutable weth;

  constructor(address _weth) {
    // Find the registryProvider address and store it
    (bool succ, bytes memory _registry) = addressProvider.call(
      abi.encodeWithSignature('function get_registry()(address)')
    );
    assert(succ);
    registry = abi.decode(_registry, (address));

    weth = _weth;
  }

  function getQuote(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut, address _pool) {
    if(_tokenIn == JBTokens.ETH) _tokenIn = weth;
    if(_tokenOut == JBTokens.ETH) _tokenOut = weth;

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
  ) external payable returns (uint256 _amountReceived){
    // Get the token indice in the pool
    (int128 i, int128 j, ) = ICurveRegistry(registry).get_coin_indices(
      _pool,
      _tokenIn == JBTokens.ETH ? weth : _tokenIn,
      _tokenOut == JBTokens.ETH ? weth : _tokenOut
    );

    if(_tokenIn != JBTokens.ETH) {
      // Pull the token
      IERC20(_tokenOut).transferFrom(msg.sender, address(this), _amountIn);

      // Approve the swapped token
      IERC20(_tokenIn).approve(_pool, _amountIn);
    }

    // Swap - no slippage allowed, as the quote and swap are atomic. use_eth will wrap/unwrap eth as needed
    _amountReceived = ICurvePool(_pool)
      .exchange{value: _tokenIn == JBTokens.ETH ? _amountIn : 0}(
        {
          i: i, 
          j: j, 
          dx: _amountIn, 
          min_dy: _amountOut, 
          use_eth: (_tokenIn == JBTokens.ETH || _tokenOut == JBTokens.ETH)
        }
      );

    // Send eth if eth is requested
    if(_tokenOut == JBTokens.ETH) {
      payable(msg.sender).transfer(_amountReceived);
    }
    // Approve the token received
    else IERC20(_tokenOut).approve(msg.sender, _amountReceived);
  }

  // Receive eth if tokenOut == eth
  receive() external payable {}
}
