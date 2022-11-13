// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@jbx-protocol-v1/contracts/interfaces/IModAllocator.sol';

/**
 @title
 Juicebox split allocator for allocating v1 treasury funds to v3 treasury
*/
contract V1Allocator is ERC165, IModAllocator {
  error TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();
  function allocate(uint256 _projectId, uint256 _forProjectId, address _beneficiary) external payable override {
    // avoid compiler warnings
    _projectId; 
    _forProjectId;
    // send eth to the beneficiary
    (bool success, ) = _beneficiary.call{ value: msg.value, gas: 20000 }("");
    if (!success) {
        revert TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();
    }
  }

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    override
    returns (bool)
  {
    return
      _interfaceId == type(IModAllocator).interfaceId || super.supportsInterface(_interfaceId);
  }
}
