// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@jbx-protocol-v1/contracts/interfaces/IModAllocator.sol';
import '@jbx-protocol-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol-v3/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol-v3/contracts/libraries/JBTokens.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 @title
 Juicebox split allocator for allocating v1 treasury funds to v3 treasury
*/
contract V1Allocator is ERC165, IModAllocator, ReentrancyGuard {
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

    @param _projectId project id from where the funds will be transferred from.
    @param _forProjectId project id where the funds will be transferred to.
    @param _beneficiary beneficiary to transfer the funds to
  */
  function allocate(uint256 _projectId, uint256 _forProjectId, address _beneficiary) external payable nonReentrant override {
    // avoid compiler warnings
    _projectId;
    _beneficiary;

    // eth terminal
    IJBPaymentTerminal _terminal = directory.primaryTerminalOf(_forProjectId, JBTokens.ETH);

    if (address(_terminal) == address(0)) revert TERMINAL_NOT_FOUND();
    
    // add to balance of v3 terminal for the project
    _terminal.addToBalanceOf{value: msg.value}(
        _forProjectId,
        msg.value,
        JBTokens.ETH,
        "v1 -> v3 allocation",
        bytes("")
    );
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

