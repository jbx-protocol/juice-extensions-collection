// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Test } from 'forge-std/Test.sol';
import { Mainnet_UniswapV2 } from '../example/swapAllocator/poolWrappers/Mainnet_UniswapV2.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract SwapAllocator_UniV2_Test is Test {
  address constant _uniV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  // 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc eth usdc
  // 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5 dai usdc

  Mainnet_UniswapV2 _wrapper;
  address tokenIn = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC - Has to be fixed for the create2 deterministic address
  address tokenOut = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
  address weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  // Deterministic addresses for tokenIn-tokenOut or tokenIn-weth pool
  address InOutPool = 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5;
  address InWethPool = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
  address payable caller;
  
  function setUp() public {
    caller =  payable(makeAddr('caller'));

    vm.etch(tokenIn, new bytes(69));
    vm.etch(tokenOut, new bytes(69));
    vm.etch(weth, new bytes(69));
    vm.etch(InOutPool, new bytes(69));
    vm.etch(InWethPool, new bytes(69));

    vm.label(tokenIn, "tokenIn");
    vm.label(tokenOut, "tokenOut");
    vm.label(weth, "weth");
    vm.label(InOutPool, "InOutPool");
    vm.label(InWethPool, "InWethPool");

    _wrapper = new Mainnet_UniswapV2(_uniV2Factory, weth);
  }
  
  /**

  @notice Theoretical amount of token out is 997/1000 (0.3% of Uniswap v2 fee deducted on token out).
          This is computed as the price = (amountIn * 997 * reserveOut) / ((reserveIn * 1000) + (amountIn*997))
          (see https://betterprogramming.pub/uniswap-v2-in-depth-98075c826254 for instance for details)

  @dev    Tests are including the 0 amountIn case

  */
  function test_getQuote_getAQuote_erc20(uint128 _amountIn, bool _inIsOut) public {
    // Try both token address order
    if(_inIsOut) (tokenIn, tokenOut) = (tokenOut, tokenIn);

    // Avoiding pool edge case (ie k of 1/10**18 for instance)
    uint112 _reserveIn = 123 * 10**18;
    uint112 _reserveOut = 321 * 10**18;

    uint256 _numerator = uint256(_amountIn) * 997 * _reserveOut;
    uint256 _denumerator = _reserveIn * 1000 + (uint256(_amountIn) * 997);
    uint256 _amountOut =  _numerator / _denumerator;

    // getReserves return the sorted reserves -> sort reserveIn & Out
    (uint112 _reserve0, uint112 _reserve1) = tokenIn < tokenOut ? (_reserveIn, _reserveOut) : (_reserveOut, _reserveIn);
    
    // Mock the quote, third arg of get reserves is discarded
    vm.mockCall(InOutPool, abi.encodeCall(IUniswapV2Pair.getReserves, ()), abi.encode(_reserve0, _reserve1, 69));
    (uint256 _amountOutQuoted,) = _wrapper.getQuote(_amountIn, tokenIn, tokenOut);

    // Check: correct amount out?
    assertEq(_amountOut, _amountOutQuoted);
  }

  function test_getQuote_getAQuote_ethIn(uint128 _amountIn) public {
    uint112 _reserveIn = 123 * 10**18;
    uint112 _reserveOut = 321 * 10**18;

    uint256 _numerator = uint256(_amountIn) * 997 * _reserveOut;
    uint256 _denumerator = _reserveIn * 1000 + (uint256(_amountIn) * 997);
    uint256 _amountOut =  _numerator / _denumerator;

    // getReserves return the sorted reserves -> sort reserveIn & Out
    (uint112 _reserve0, uint112 _reserve1) = weth < tokenIn ? (_reserveIn, _reserveOut) : (_reserveOut, _reserveIn);
    
    // Mock the quote, third arg of get reserves is discarded - eth is in, tokenIn is out
    vm.mockCall(InWethPool, abi.encodeCall(IUniswapV2Pair.getReserves, ()), abi.encode(_reserve0, _reserve1, 69));
    (uint256 _amountOutQuoted,) = _wrapper.getQuote(_amountIn, JBTokens.ETH, tokenIn);

    // Check: correct amount out?
    assertEq(_amountOut, _amountOutQuoted);
  }

  function test_getQuote_getAQuote_ethOut(uint128 _amountIn) public {
    uint112 _reserveIn = 123 * 10**18;
    uint112 _reserveOut = 321 * 10**18;

    uint256 _numerator = uint256(_amountIn) * 997 * _reserveOut;
    uint256 _denumerator = _reserveIn * 1000 + (uint256(_amountIn) * 997);
    uint256 _amountOut =  _numerator / _denumerator;

    // getReserves return the sorted reserves -> sort reserveIn & Out
    (uint112 _reserve0, uint112 _reserve1) = tokenIn < weth ? (_reserveIn, _reserveOut) : (_reserveOut, _reserveIn);
    
    // Mock the quote, third arg of get reserves is discarded - tokenIn is in, eth is out
    vm.mockCall(InWethPool, abi.encodeCall(IUniswapV2Pair.getReserves, ()), abi.encode(_reserve0, _reserve1, 69));
    (uint256 _amountOutQuoted,) = _wrapper.getQuote(_amountIn, tokenIn, JBTokens.ETH);

    // Check: correct amount out?
    assertEq(_amountOut, _amountOutQuoted);
  }

  function test_swap_transferTokenAndSwap_erc20(uint256 _amountIn, uint256 _amountOut, bool _inIsOut) public {
    // Try both token order
    uint256 _amount0;
    uint256 _amount1;

    // IUniswapV2Pair.swap only expects the amount of token out (token1 or 2) as calldata
    if(_inIsOut) {
      (tokenIn, tokenOut) = (tokenOut, tokenIn);
      (_amount0, _amount1) = (0, _amountOut);
    } else 
      (_amount0, _amount1) = (_amountOut, 0);
    
    // Mock & expect the transfer from the caller to the pool ("caller" is the allocator in this context)
    vm.mockCall(tokenIn, abi.encodeCall(IERC20.transferFrom, (caller, InOutPool, _amountIn)), abi.encode(true));
    vm.expectCall(tokenIn, abi.encodeCall(IERC20.transferFrom, (caller, InOutPool, _amountIn)));

    // Mock & expect the swap itself
    vm.mockCall(InOutPool, abi.encodeCall(IUniswapV2Pair.swap, (_amount0, _amount1, caller, new bytes(0))), abi.encode());
    vm.expectCall(InOutPool, abi.encodeCall(IUniswapV2Pair.swap, (_amount0, _amount1, caller, new bytes(0))));

    // Mock & expect the new balance of tokenOut, after the swap
    vm.mockCall(tokenOut, abi.encodeCall(IERC20.balanceOf, (address(_wrapper))), abi.encode(_amountOut));
    vm.expectCall(tokenOut, abi.encodeCall(IERC20.balanceOf, (address(_wrapper))));

    // Mock & expect the approval of the token out to the caller
    vm.mockCall(tokenOut, abi.encodeCall(IERC20.approve, (caller, _amountOut)), abi.encode(true));
    vm.expectCall(tokenOut, abi.encodeCall(IERC20.approve, (caller, _amountOut)));

    vm.prank(caller);
    _wrapper.swap(_amountIn, tokenIn, tokenOut, _amountOut, InOutPool);
  }

  function test_swap_transferTokenAndSwap_ethIn() public {
  }

  function test_swap_transferTokenAndSwap_ethOut() public {
  }

}
