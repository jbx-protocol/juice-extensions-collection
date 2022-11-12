// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Test } from 'forge-std/Test.sol';
import { Mainnet_UniswapV2 } from '../example/swapAllocator/poolWrappers/Mainnet_UniswapV2.sol';

contract SwapAllocator_Test is Test {
  Mainnet_UniswapV2 _wrapper;
  address _tokenIn;
  address _tokenOut;
  address payable _beneficiary;
  
  function setUp() public {
    _tokenIn = makeAddr('_tokenOut');
    _tokenOut = makeAddr('_tokenOut');
    _beneficiary =  payable(makeAddr('_beneficiary'));

    vm.etch(_tokenIn, new bytes(69));
    vm.etch(_tokenOut, new bytes(69));

    _wrapper = new Mainnet_UniswapV2();
  }

  function test_getQuote_getAQuote() public {
  }

  function test_getQuote_returnZeroIfNoQuote() public {
  }

  function test_swap_transferTokenAndSwap() public {
  }

  function test_swap_doNotRevertIfSwapFails() public {
  }

}
