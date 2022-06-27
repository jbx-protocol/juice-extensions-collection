// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol-v2/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol-v2/contracts/libraries/JBCurrencies.sol';
import '@jbx-protocol-v2/contracts/libraries/JBTokens.sol';

import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';



/**
 @notice Datasource providing a proxy to multiple datasources

 @dev Used to combine multiple datasources when they all have intended effect.
      There are 3 modes for computing the weight to return:
      - favorite: only a specified datasource will act as the source of truth
      - mean: an arithmetic mean between every weights returned is used
      - none: a 0 weight is always returned

      There are only 2 modes for the memo: favorite and none

      The delegate has 2 modes too: fixed (set in this contract) and favorite (based on one datasource)
*/

contract MultiFundingCycleDataSource is IJBFundingCycleDataSource, ERC165 {
  enum reconciliationMode { None, Mean, Fixed, Favorite };

  reconciliationMode public weightReconcilitationMode;
  reconciliationMode public memoReconciliationMode;
  reconciliationMode public delegateReconciliationMode;

  IJBPayDelegate public defaultDelegate;

  constructor(IJBPayDelegate _defaultDelegate) {
    defaultDelegate = _defaultDelegate;
  }

  function payParams(JBPayParamsData calldata _param)
    external
    view
    override
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate
    )
  {
    return (_param.weight, _param.memo, NFTDelegate);
  }

  function redeemParams(JBRedeemParamsData calldata _param)
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    )
  {
    return (_param.reclaimAmount.value, 'bye holder', IJBRedemptionDelegate(address(0)));
  }

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    override(IERC165, ERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      super.supportsInterface(_interfaceId);
  }
}
