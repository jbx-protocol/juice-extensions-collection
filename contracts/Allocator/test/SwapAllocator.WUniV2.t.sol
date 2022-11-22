// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Test } from 'forge-std/Test.sol';
import { Mainnet_UniswapV2 } from '../example/swapAllocator/poolWrappers/Mainnet_UniswapV2.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

contract SwapAllocator_UniV2_Test is Test {
  address constant _uniV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  // 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc eth usdc
  // 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5 dai usdc

  Mainnet_UniswapV2 _wrapper;
  address _tokenIn = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC - Has to be fixed for the create2 deterministic address
  address _tokenOut = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
  address _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  // Deterministic addresses for tokenIn-tokenOut or tokenIn-weth pool
  address _InOutPool = 0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5;
  address _InWethPool = 0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc;
  address payable _beneficiary;
  
  function setUp() public {
    _beneficiary =  payable(makeAddr('_beneficiary'));

    vm.etch(_tokenIn, new bytes(69));
    vm.etch(_tokenOut, new bytes(69));
    vm.etch(_weth, new bytes(69));
    vm.etch(_InOutPool, new bytes(69));
    vm.etch(_InWethPool, new bytes(69));

    vm.label(_tokenIn, "_tokenIn");
    vm.label(_tokenOut, "_tokenOut");
    vm.label(_weth, "_weth");
    vm.label(_InOutPool, "_InOutPool");
    vm.label(_InWethPool, "_InWethPool");

    _wrapper = new Mainnet_UniswapV2(_uniV2Factory, _weth);
  }
  
  /**  
  @notice Theoretical amount of token out is 997/1000 (0.3% of Uniswap v2 fee deducted on token out).
          This is computed as the price = (amountIn * 997 * reserveOut) / ((reserveIn * 1000) + (amountIn*997))
          (see https://betterprogramming.pub/uniswap-v2-in-depth-98075c826254 for instance for details)

  */
  function test_getQuote_getAQuote_erc20(uint128 _amountIn) public {
    vm.assume(_amountIn > 0);
    uint112 _reserveIn = 123 * 10**18;
    uint112 _reserveOut = 321 * 10**18;

    uint256 _numerator = uint256(_amountIn) * 997 * _reserveOut;
    uint256 _denumerator = _reserveIn * 1000 + (uint256(_amountIn) * 997);
    uint256 _amountOut =  _numerator / _denumerator;

    (uint112 _reserve0, uint112 _reserve1) = _tokenIn < _tokenOut ? (_reserveIn, _reserveOut) : (_reserveOut, _reserveIn);
    
    vm.mockCall(_InOutPool, abi.encodeCall(IUniswapV2Pair.getReserves, ()), abi.encode(_reserve0, _reserve1, 69));
    (uint256 _amountOutQuoted,) = _wrapper.getQuote(_amountIn, _tokenIn, _tokenOut);

    assertEq(_amountOut, _amountOutQuoted);
  }

  function test_getQuote_getAQuote_ethIn() public {

  }

  function test_getQuote_getAQuote_ethOut() public {

  }

  function test_getQuote_returnZeroIfNoQuote() public {
  }

  function test_swap_transferTokenAndSwap() public {
  }

  function test_swap_doNotRevertIfSwapFails() public {
  }

}
