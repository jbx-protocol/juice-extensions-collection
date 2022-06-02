// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
//import '@jbx-protocol-v2/contracts/interfaces/IJBSplitAllocator.sol';
import '@jbx-protocol-v2/contracts/structs/JBSplitAllocationData.sol';

/**
 @title
 Juicebox split allocator

 @notice
 This is an allocator template, used as a recipient of a payout split, to add an extra layer of logic in fund allocation
*/
contract Allocator is ERC165, IJBSplitAllocator {
  //@inheritdoc IJBAllocator
  function allocate(JBSplitAllocationData calldata _data) external payable override {
    // Do something with the fund received
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
