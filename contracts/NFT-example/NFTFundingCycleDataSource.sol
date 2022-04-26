// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol-v2/contracts/interfaces/IJBFundingCycleDataSource.sol';

contract NFTFundingCycleDataSource is IJBFundingCycleDataSource {
  IJBPayDelegate NFTDelegate;

  constructor(IJBPayDelegate _delegate) {
    NFTDelegate = _delegate;
  }

  function payParams(JBPayParamsData calldata _param)
    external
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate,
      bytes memory delegateMetadata
    )
  {
    return (_param.weight, _param.memo, NFTDelegate, new bytes(0));
  }

  function redeemParams(JBRedeemParamsData calldata _param)
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate,
      bytes memory delegateMetadata
    )
  {
    return (0, '', IJBRedemptionDelegate(address(0)), new bytes(0));
  }
}
