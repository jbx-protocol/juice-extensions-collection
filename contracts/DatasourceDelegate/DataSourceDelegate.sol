// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBRedemptionDelegate.sol';

/**
 @title
 Juicebox Datasource & delegate templates

 @notice
 This is a datasource and delegate template. the two are combined within a single contract, for convenience.
*/
contract DataSourceDelegate is IJBFundingCycleDataSource, IJBPayDelegate, IJBRedemptionDelegate {
  //@inheritdocs IJBFundingCycleDataSource
  function payParams(JBPayParamsData calldata _data)
    external
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      JBPayDelegateAllocation[] memory delegate
    )
  {
    delegate = new JBPayDelegateAllocation[](1);
    delegate[0] = JBPayDelegateAllocation({delegate: IJBPayDelegate(this), amount: 0});
    return (0, _data.memo, delegate);
  }

  //@inheritdocs IJBFundingCycleDataSource
  function redeemParams(JBRedeemParamsData calldata)
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      JBRedemptionDelegateAllocation[] memory delegate
    )
  {
    delegate = new JBRedemptionDelegateAllocation[](1);
    delegate[0] = JBRedemptionDelegateAllocation({
      delegate: IJBRedemptionDelegate(this),
      amount: 0
    });

    return (0, '', delegate);
  }

  //@inheritdocs IJBPayDelegate
  function didPay(JBDidPayData calldata _data) external payable override {}

  //@inheritdocs IJBRedemptionDelegate
  function didRedeem(JBDidRedeemData calldata _data) external payable override {}

  function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
    return
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId ||
      _interfaceId == type(IJBRedemptionDelegate).interfaceId;
  }
}
