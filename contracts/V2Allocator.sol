// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@jbx-protocol-v2/contracts/structs/JBSplitAllocationData.sol';
import '@jbx-protocol-v2/contracts/interfaces/IJBTokenStore.sol';
import '@jbx-protocol-v2/contracts/libraries/JBTokens.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

/**
 @title
 Juicebox split allocator for allocating v2 treasury funds to v3 treasury
*/
contract V2Allocator is ERC165, IJBSplitAllocator {
  //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();

  /**
    @notice
    The token store address.
  */
  IJBTokenStore public immutable tokenStore;


  /**
    @param _tokenStore token store address. 
  */
  constructor(IJBTokenStore _tokenStore) {
    tokenStore = _tokenStore;
  }

  /**
    @notice
    Allocate hook that will transfer treasury funds to v3.

    @param _data allocation config which specifies the beneficiary, split info
  */
  function allocate(JBSplitAllocationData calldata _data) external payable override {    
    if (_data.token == JBTokens.ETH) {
      // send eth to the beneficiary
      (bool success, ) = _data.split.beneficiary.call{ value: msg.value, gas: 20000 }("");
      // check if the transfer was successful
      if (!success) {
        revert TRANSACTIONAL_TOKEN_TRANSFER_FAILURE();
      }
    } else if (address(tokenStore.tokenOf(_data.projectId)) != _data.token) {
        // if the allocation comes from a erc20 termianl just do a simple transfer
        IERC20(_data.token).transferFrom(msg.sender, _data.split.beneficiary, _data.amount);
    } else {
        if (_data.split.preferClaimed) {
        // if the allocation comes from a controller and preferClaimed is true then tokens are already minted to the allocator so just transfer
           tokenStore.tokenOf(_data.projectId).transfer(_data.projectId, _data.split.beneficiary, _data.amount);     
        } else {
          // if the allocation comes from a controller and preferClaimed is false then transfer the unclaimed balance to the beneficiary
           tokenStore.transferFrom(address(this), _data.projectId,  _data.split.beneficiary, _data.amount);
        }
    }
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
