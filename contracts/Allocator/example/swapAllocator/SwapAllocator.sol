// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@jbx-protocol-v2/contracts/structs/JBSplitAllocationData.sol';

import './interfaces/ICurveRegistry.sol';
import './interfaces/ICurvePool.sol';

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
contract SwapAllocator is ERC165, IJBSplitAllocator {
  //@inheritdoc IJBAllocator
  function allocate(JBSplitAllocationData calldata _data) external payable override {
    // Get best quote between Curve and Uniswap (others can be added)

    // Curve
    address pool = ICurveRegistry(registry).find_pool_for_coins(tokenIn, tokenOut, 0);
    (int128 fromIndex, int128 toIndex, ) = ICurveRegistry(registry).get_coin_indices(
      pool,
      tokenIn,
      tokenOut
    );
    uint256 curveQuote = ICurvePool(pool).get_dy(fromIndex, toIndex, amount);

    // UniV2
    address pairAddress = _computePairAddressUniV2(tokenIn, tokenOut);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();
    uint256 _uniswapV2Quote = _computeAmountOutWithFee(amount, reserve0, reserve1);

    // UniV3
    (address _token0, address _token1) = MultiOracleLib.sortPairs(_tokenIn, _tokenOut);
    uint24 _fee = governanceDecidedFee[_token0][_token1] != 0
      ? governanceDecidedFee[_token0][_token1]
      : defaultFee;

    address _pair = PoolAddress.computeAddress(
      address(0x1F98431c8aD98523631AE4a59f267346ea31F984), // UniV3 Factory
      PoolAddress.getPoolKey(_token0, _token1, _fee)
    );

    (uint160 _sqrtPriceX96, , , , , , ) = IUniswapV3Pool(_pair).slot0();

    // Return amount out with "not so bad" precision (if not overflowing) : TODO: replace by uniV3 lib (there must be one)
    if (_sqrtPriceX96 <= type(uint128).max) {
      uint256 ratioX192 = uint256(_sqrtPriceX96) * _sqrtPriceX96;
      _twapAmountOut = _tokenIn < _tokenOut
        ? FullMath.mulDiv(ratioX192, _amountIn, 1 << 192)
        : FullMath.mulDiv(1 << 192, _amountIn, ratioX192);
    } else {
      uint256 ratioX128 = FullMath.mulDiv(_sqrtPriceX96, _sqrtPriceX96, 1 << 64);
      _twapAmountOut = _tokenIn < _tokenOut
        ? FullMath.mulDiv(ratioX128, _amountIn, 1 << 128)
        : FullMath.mulDiv(1 << 128, _amountIn, ratioX128);
    }

    // Compare and swap accordingly
  }

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    override(IERC165, ERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBSplitAllocator).interfaceId || super.supportsInterface(_interfaceId);
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
    //bytes32 to address:
    assembly {
      mstore(0x0, pubKey) //scratch space
      pair := mload(0x0) //address = 20bytes right end of 32bytes pub key
    }
  }

  // UniV2 only
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
