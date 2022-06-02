// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol-v2/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol-v2/contracts/interfaces/IJBPayDelegate.sol';
import '@jbx-protocol-v2/contracts/interfaces/IJBRedemptionDelegate.sol';

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
      IJBPayDelegate delegate
    )
  {
    return (0, _data.memo, IJBPayDelegate(address(this)));
  }

  //@inheritdocs IJBFundingCycleDataSource
  function redeemParams(JBRedeemParamsData calldata)
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    )
  {
    return (0, '', IJBRedemptionDelegate(address(this)));
  }

  //@inheritdocs IJBPayDelegate
  function didPay(JBDidPayData calldata _data) external override {}

  //@inheritdocs IJBRedemptionDelegate
  function didRedeem(JBDidRedeemData calldata _data) external override {}

  function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
    return
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId ||
      _interfaceId == type(IJBRedemptionDelegate).interfaceId;
  }
}
