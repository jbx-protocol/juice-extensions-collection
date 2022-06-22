// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@jbx-protocol-v2/contracts/interfaces/IJBSplitAllocator.sol';
import '@jbx-protocol-v2/contracts/interfaces/IJBSplitsStore.sol';

/**
 @title
 Juicebox sunset split allocator

 @notice
 This is an allocator example managing a group of splits (number 3) with a defined expiration for each beneficiary.
 Upon expiration, the beneficiary stops receiving payment and the unallocated fund is sent back to the project's treasury
*/
contract Allocator is ERC165, IJBSplitAllocator {
  //@inheritdoc IJBAllocator
  function allocate(JBSplitAllocationData calldata _data) external payable override {
    JBSplit[] memory _splits = splitsStore.splitsOf(
      _data.projectId,
      /*_domain*/
      0,
      _data.group
    );

    // Do something with the fund received
    // address token;
    // uint256 amount;
    // uint256 decimals;
    // uint256 projectId;
    // uint256 group;
    // JBSplit split;
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
