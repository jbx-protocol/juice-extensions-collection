// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.6;

// import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
// import '@jbx-protocol-v1/contracts/interfaces/IModAllocator.sol';

// /**
//  @title
//  Juicebox split allocator

//  @notice
//  This is an allocator template, used as a recipient of a payout split, to add an extra layer of logic in fund allocation
// */
// contract V1Allocator is ERC165, IModAllocator {

//   function allocate(uint256 _projectId, uint256 _forProjectId, address _beneficiary) external payable override {
//     // Do something with the fund received
    
//     // if (_data.token == JBTokens.ETH) {
//     //   _data.split.beneficiary.call({value: msg.value, gas: 3000});
//     // } else if (tokenStore.tokenOf(_ddata.projectId) != _data.token) {
//     //   IERC20(_data.token).transferFrom(msg.sender, _data.split.beneficiary, _data.amount);
//     // } else {
//     //   tokenStore.trans
//     // }
//   }

//   function supportsInterface(bytes4 _interfaceId)
//     public
//     view
//     override(IERC165, ERC165)
//     returns (bool)
//   {
//     return
//       _interfaceId == type(IJBSplitAllocator).interfaceId || super.supportsInterface(_interfaceId);
//   }
// }
