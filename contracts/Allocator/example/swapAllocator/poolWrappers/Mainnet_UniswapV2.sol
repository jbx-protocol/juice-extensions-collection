// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '../interfaces/IPoolWrapper.sol';

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol';


/**
 @title

 @notice

 @dev     This wrapper uses the Uniswap V2 mainnet pool bytecode and 0.3% fee, it 
          needs to be adapted for uniswap clones
*/
contract Mainnet_UniswapV2 is IPoolWrapper {

  address immutable factory;
  address immutable weth;

  constructor(address _factory, address _weth) {
    factory = _factory; // uniV2 mainnet 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    weth = _weth; // weth mainnet
  }

  function getQuote(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut, address _pool) {
    if(_amountIn == 0) return(0, address(0));
    if(_tokenIn == JBTokens.ETH) _tokenIn = weth;
    if(_tokenOut == JBTokens.ETH) _tokenOut = weth;

    _pool = _pairFor(_tokenIn, _tokenOut);

    (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(_pool).getReserves();
    
    // reserve0 is the tokenIn
    (reserve0, reserve1) = _tokenIn < _tokenOut ? (reserve0, reserve1) : (reserve1, reserve0);

    _amountOut = _getAmountOut(_amountIn, reserve0, reserve1);
  }

  function swap(
    uint256 _amountIn,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountOut,
    address _pool
  ) external payable returns (uint256 _amountReceived){
    if(_tokenIn == JBTokens.ETH) {
      _amountIn = msg.value;

      IWETH(weth).deposit{value: _amountIn}();

      _tokenIn = weth;

      // Optimistically transfer the weth to the uniswap pool
      IERC20(weth).transfer(_pool, _amountIn);
    }
    else   
      // Optimistically transfer the tokenIn to the uniswap pool
      IERC20(_tokenIn).transferFrom(msg.sender, _pool, _amountIn);

    // Assign the amount out,
    (uint256 amount0Out, uint256 amount1Out) = _tokenIn < (_tokenOut == JBTokens.ETH ? weth : _tokenOut)
      ? (uint256(0), _amountOut)
      : (_amountOut, uint256(0));

    // Perform the swap
    IUniswapV2Pair(_pool).swap(amount0Out, amount1Out, msg.sender, new bytes(0));

    // Check what we received
    _amountReceived = IERC20(_tokenOut == JBTokens.ETH ? weth : _tokenOut).balanceOf(address(this));

    // Unwrap weth if eth is requested
    if(_tokenOut == JBTokens.ETH) {
      IERC20(weth).approve(weth, _amountReceived);
      IWETH(weth).withdraw(_amountReceived);
      payable(msg.sender).transfer(_amountReceived);
    }
    // Approve the token received
    else IERC20(_tokenOut).approve(msg.sender, _amountReceived);
  }

  /**
    @notice Compute the pool address based on a given factory and pool bytecode

    @dev    The bytecode and factory changes in other uniswap clone, redeploying
            correct wrapper for each is required.
  */
  function _pairFor(address _token0, address _token1)
    internal
    view
    returns (address pair)
  {
    (_token0, _token1) = _token0 < _token1 ? (_token0, _token1) : (_token1, _token0);

    bytes32 pubKey = keccak256(
      abi.encodePacked(
        hex'ff',
        factory,
        keccak256(abi.encodePacked(_token0, _token1)),
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
      )
    );

    assembly { pair := pubKey }
  }

  /**
    @notice Compute the amount of token received after swapping, given current pool reserves and
            uniswap 0.3% fee (adapt based on potential differences in fee in other clones)
  */
  function _getAmountOut(
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
