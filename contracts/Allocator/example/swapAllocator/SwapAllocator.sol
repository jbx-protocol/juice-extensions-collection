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

 @dev does NOT support fee on transfer token. Revert should be handled in this implementation, wrappers are optimistic
*/
contract SwapAllocator is ERC165, Ownable, IJBSplitAllocator {
  event SwapAllocated(address indexed beneficiary, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut);
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

      // Get a quote (expressed as a net amount of token received for an amount of token sent)
      try _currentWrapper.getQuote(_amountIn, _tokenIn, _tokenOut) returns(uint256 _quote, address _pool) {
        // If the amount received from this dex is higher, save this wrapper
        if (_quote > _bestQuote) {
          _bestPool = _pool;
          _bestQuote = _quote;
          _bestWrapper = _currentWrapper;
        }
      }
      catch {}

      unchecked {
        ++i;
      }
    }

    uint256 _amountReceived;

    // If a swap should be possible, try it
    if(_bestQuote != 0) {
      // If ERC20, approve the wrapper
      if(_tokenIn != JBTokens.ETH) IERC20(_tokenIn).approve(address(_bestWrapper), _amountIn);

      // Call swap with the appropriate value, avoid reverting by returning 0 if fails
      try _bestWrapper.swap{value: _tokenIn == JBTokens.ETH ? _amountIn : 0}(_amountIn, _tokenIn, _tokenOut, _bestQuote, _bestPool) returns(uint256 _received) {
        _amountReceived = _received;
      }
      catch {
        // implicit: _amountReceived = 0;
      }
    }

    // If the swap was succesful, transfer token
    if(_amountReceived != 0)
      // Send the eth or token received to the beneficiary
      if(_tokenOut == JBTokens.ETH) payable(_beneficiary).transfer(address(this).balance);
      else IERC20(_tokenOut).transferFrom(address(_bestWrapper), _beneficiary, _amountReceived); // Transfer the token to the beneficiary

    // If no swap was performed (no best quote or received 0), send the original token to the beneficiary
    else 
      if(_tokenIn == JBTokens.ETH) payable(_beneficiary).transfer(msg.value); 
      else IERC20(_tokenIn).transfer(_beneficiary, _amountIn);

    emit SwapAllocated({
      beneficiary: _beneficiary,
      tokenIn: _tokenIn,
      tokenOut: _tokenOut,
      amountIn: _amountIn,
      amountOut: _amountReceived
    });
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
