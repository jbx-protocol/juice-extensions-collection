// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@jbx-protocol-v2/contracts/structs/JBSplitAllocationData.sol';
import '@jbx-protocol-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol-v3/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol-v3/contracts/libraries/JBTokens.sol';

/**
 @title
 Juicebox split allocator for allocating v2 treasury funds to v3 treasury
*/
contract V2Allocator is ERC165, IJBSplitAllocator, ReentrancyGuard {
 //*********************************************************************//
  // --------------------------- custom errors ------------------------- //
  //*********************************************************************//
  error TERMINAL_NOT_FOUND();


  /**
    @notice
    The jb directory address.
  */
  IJBDirectory public immutable directory;

  /**
    @param _directory directory address. 
  */
  constructor(IJBDirectory _directory) {
    directory = _directory;
  }

  /**
    @notice
    Allocate hook that will transfer treasury funds to v3.

    @param _data allocation config which specifies the beneficiary, split info
  */
  function allocate(JBSplitAllocationData calldata _data) external payable nonReentrant override {    
    // eth terminal
    IJBPaymentTerminal _terminal = directory.primaryTerminalOf( _data.projectId, JBTokens.ETH);

    if (address(_terminal) == address(0)) revert TERMINAL_NOT_FOUND();
    
    // add to balance of v3 terminal for the project
    _terminal.addToBalanceOf{value: msg.value}(
        _data.projectId,
        msg.value,
        JBTokens.ETH,
        "v2 -> v3 allocation",
        bytes("")
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

