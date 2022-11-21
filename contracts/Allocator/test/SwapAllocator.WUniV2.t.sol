// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { Test } from 'forge-std/Test.sol';
import { Mainnet_UniswapV2 } from '../example/swapAllocator/poolWrappers/Mainnet_UniswapV2.sol';

contract SwapAllocator_UniV2_Test is Test {
  address constant _uniV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
  
  Mainnet_UniswapV2 _wrapper;
  address _tokenIn;
  address _tokenOut;
  address _weth;
  address payable _beneficiary;
  
  function setUp() public {
    _tokenIn = makeAddr('_tokenOut');
    _tokenOut = makeAddr('_tokenOut');
    _tokenOut = makeAddr('_weth');
    _beneficiary =  payable(makeAddr('_beneficiary'));

    vm.etch(_tokenIn, new bytes(69));
    vm.etch(_tokenOut, new bytes(69));
    vm.etch(_weth, new bytes(69));

    _wrapper = new Mainnet_UniswapV2(_uniV2Factory, _weth);
  }

  function test_getQuote_getAQuote(address _tokenIn, address _tokenOut) public {

  }

  function test_getQuote_returnZeroIfNoQuote() public {
  }

  function test_swap_transferTokenAndSwap() public {
  }

  function test_swap_doNotRevertIfSwapFails() public {
  }

}
