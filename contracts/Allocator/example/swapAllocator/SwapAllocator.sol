// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBSplitAllocationData.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol';

import './interfaces/IPoolWrapper.sol';
import './interfaces/ICurveRegistry.sol';
import './interfaces/ICurvePool.sol';

/**
 @title
 Juicebox split allocator - swap to another asset

 @notice

 @dev does NOT support fee on transfer token
*/
contract SwapAllocator is ERC165, Ownable, IJBSplitAllocator {
  event NewDex(IPoolWrapper);
  event RemoveDex(IPoolWrapper);

  // All the dexes for this allocator token tuple
  IPoolWrapper[] public dexes;

  // The token which should be distributed to the beneficiary
  address tokenOut;

  constructor(
    address _tokenOut,
    IPoolWrapper[] memory _dexes
  ) {
    dexes = _dexes;
    tokenOut = _tokenOut;
  }

  function addDex(IPoolWrapper _newDex) external onlyOwner {
    dexes.push(_newDex);
    emit NewDex(_newDex);
  }

  function removeDex(IPoolWrapper _dexToRemove) external onlyOwner {
    uint256 _numberOfDexes = dexes.length;
    IPoolWrapper _currentWrapper;

    for(uint i; i < _numberOfDexes;) {
      _currentWrapper = dexes[i];

      // Swap and pop
      if(_currentWrapper == _dexToRemove) {
        dexes[i] = dexes[_numberOfDexes - 1];
        dexes.pop();
        break;
      }

      unchecked {
        ++i;
      }
    }

    emit RemoveDex(_dexToRemove);
  }

  //@inheritdoc IJBAllocator
  function allocate(JBSplitAllocationData calldata _data) external payable override {
    uint256 _amountIn = _data.amount;
    address _tokenIn = _data.token;
    address _tokenOut = tokenOut;
    address _beneficiary = _data.split.beneficiary;

    // Keep record of the best pool wrapper. The pool address is passed to avoid having
    // to find it again in the wrapper
    address _bestPool;
    uint256 _bestQuote;
    IPoolWrapper _bestWrapper;

    // Keep a reference to the stored wrapper
    IPoolWrapper _currentWrapper;
    uint256 _activeDexes = dexes.length;
    for (uint256 i; i < _activeDexes; ) {
      _currentWrapper = dexes[i];

      // Get a quote (expressed as an amount of token received for an amount of token sent)
      (uint256 _quote, address _pool) = _currentWrapper.getQuote(_amountIn, _tokenIn, _tokenOut);

      // If the amount received from this dex is higher, save this wrapper
      if (_quote > _bestQuote) {
        _bestPool = _pool;
        _bestQuote = _quote;
        _bestWrapper = _currentWrapper;
      }

      unchecked {
        ++i;
      }
    }

    if(_bestQuote != 0) {
      // If ERC20, approve the wrapper
      if(_tokenIn != JBTokens.ETH) IERC20(_tokenIn).approve(address(_bestWrapper), _amountIn);

      // Call swap with the appropriate value
      uint256 _amountReceived = _bestWrapper.swap{value: _tokenIn == JBTokens.ETH ? _amountIn : 0}(_amountIn, _tokenIn, _tokenOut, _bestQuote, _bestPool);

      // Send the eth or token received to the beneficiary
      if(_tokenOut == JBTokens.ETH) payable(_beneficiary).transfer(address(this).balance);
      else IERC20(_tokenOut).transferFrom(address(_bestWrapper), _beneficiary, _amountReceived); // Transfer the token to the beneficiary
    }
// TODO: _amountReceived == 0 -> tranfer tokenIn (then non-blocking logic in swap wrapper)
    // If no swap was performed, send the original token to the beneficiary
    else 
      if(_tokenIn == JBTokens.ETH) payable(_beneficiary).transfer(msg.value); 
      else IERC20(_tokenIn).transfer(_beneficiary, _amountIn);
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
}
