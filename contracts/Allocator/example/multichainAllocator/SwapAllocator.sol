// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBSplitAllocationData.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol';

import './interfaces/IAnyswapV4Router.sol';

/**
  @title  Juicebox Multichain allocator - allocate to another chain

  @notice 

  @dev    
*/
contract SwapAllocator is ERC165, Ownable, IJBSplitAllocator {
  /**
  */
  uint256 immutable targetDomain;

  IAnyswapV4Router immutable anyswapRouter = IAnyswapV4Router(0x4f3Aff3A747fCADe12598081e80c6605A8be192F);

  /**
  */
  constructor(
    uint256 _targetDomain
  ) {
    targetDomain = _targetDomain;
  }


  //@inheritdoc IJBAllocator
  function allocate(JBSplitAllocationData calldata _data) external payable override {
    // Check if amount send is < minAmount, if so, just transfer to the beneficiary on this domain (as the bridge would revert)

    // Transfer tokens to this contract / wrap and stuff as needed

    // Approve the anyswap router to spend the tokens.
    IERC20(_data.token).approve(address(anyswapRouter), _data.amount);

    // Send the token for the bridge, fee is taken on destination

// TODO: check the combination token/targetToken/anyToken (maybe mapping needed between them?)

    anyswapRouter.anySwapOutUnderlying(
      _data.token,
      _data.split.beneficiary,
      _data.amount,
      targetDomain
    );
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
