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
      There are 4 modes for computing the weight to return:
      - favorite: only a specified datasource will act as the source of truth
      - mean: an arithmetic mean between every weights returned is used
      - fixed: an arbitrary value is used
      - none: a 0 weight is always returned

      There are only 2 modes for the memo: fixed (set in this contract) and favorite (based on one datasource)

      The delegate has 2 modes too: fixed (set in this contract) and favorite (based on one datasource)
*/

contract MultiFundingCycleDataSource is IJBFundingCycleDataSource, ERC165 {
  error MultiDateSource_WeightReconciliationMismatch();

  enum reconciliationMode {
    None,
    Mean,
    Fixed,
    Favorite
  }

  reconciliationMode public weightReconcilitationMode;

  IJBFundingCycleDataSource[] public dataSources;

  // index in datasources[], if max, use fixed
  uint256 favoriteWeight = type(uint256).max;

  // index in datasources[], if max, use fixed
  uint256 favoriteMemo = type(uint256).max;

  // index in datasources[], if max, use fixed
  uint256 favoriteDelegate = type(uint256).max;

  uint256 public defaultWeight;

  string public defaultMemo;

  IJBPayDelegate public defaultDelegate;

  constructor(string memory _defaultMemo, IJBPayDelegate _defaultDelegate) {
    defaultMemo = _defaultMemo;
    defaultDelegate = _defaultDelegate;
  }

  // MAKE NON REENTRANT
  // DOC: If msg.sender==terminal check -> this should be identified as terminal!
  function payParams(JBPayParamsData calldata _param)
    external
    override
    returns (
      uint256 weight,
      string memory memo,
      IJBPayDelegate delegate
    )
  {
    reconciliationMode _weightReconcilitationMode = weightReconcilitationMode;

    uint256 _favoriteMemo = favoriteMemo;
    uint256 _favoriteDelegate = favoriteDelegate;

    if (_weightReconcilitationMode == reconciliationMode.Mean) {
      uint256 _cumSumWeights;

      uint256 _weight;
      string memory _memo;
      IJBPayDelegate _delegate;

      uint256 _numberOfDatasources = dataSources.length;
      for (uint256 i; i < _numberOfDatasources; ) {
        (_weight, _memo, _delegate) = dataSources[i].payParams(_param);

        if (_favoriteDelegate == i) delegate = _delegate;
        if (_favoriteMemo == i) memo = _memo;

        _cumSumWeights += _weight;

        unchecked {
          ++i;
        }
      }

      weight = _cumSumWeights / _numberOfDatasources;

      if (_favoriteDelegate == type(uint256).max) delegate = defaultDelegate;
      if (_favoriteMemo == type(uint256).max) memo = defaultMemo;
    } else if (_weightReconcilitationMode == reconciliationMode.Favorite) {
      uint256 _favoriteWeight = favoriteWeight;

      if (_favoriteWeight == type(uint256).max)
        revert MultiDateSource_WeightReconciliationMismatch();

      uint256 _weight;
      string memory _memo;
      IJBPayDelegate _delegate;

      uint256 _numberOfDatasources = dataSources.length;
      for (uint256 i; i < _numberOfDatasources; ) {
        (_weight, _memo, _delegate) = dataSources[i].payParams(_param);

        if (_favoriteWeight == i) weight = _weight;

        if (_favoriteDelegate == i) delegate = _delegate;

        if (_favoriteMemo == i) memo = _memo;

        unchecked {
          ++i;
        }
      }

      if (_favoriteDelegate == type(uint256).max) delegate = defaultDelegate;
      if (_favoriteMemo == type(uint256).max) memo = defaultMemo;
    } else if (_weightReconcilitationMode == reconciliationMode.Fixed) {
      string memory _memo;
      IJBPayDelegate _delegate;

      uint256 _numberOfDatasources = dataSources.length;
      for (uint256 i; i < _numberOfDatasources; ) {
        (, _memo, _delegate) = dataSources[i].payParams(_param);

        if (_favoriteDelegate == i) delegate = _delegate;

        if (_favoriteMemo == i) memo = _memo;

        unchecked {
          ++i;
        }
      }

      weight = favoriteWeight;
      if (_favoriteDelegate == type(uint256).max) delegate = defaultDelegate;
      if (_favoriteMemo == type(uint256).max) memo = defaultMemo;
    } else if (_weightReconcilitationMode == reconciliationMode.None) {
      string memory _memo;
      IJBPayDelegate _delegate;

      uint256 _numberOfDatasources = dataSources.length;
      for (uint256 i; i < _numberOfDatasources; ) {
        (, _memo, _delegate) = dataSources[i].payParams(_param);

        if (_favoriteDelegate == i) delegate = _delegate;

        if (_favoriteMemo == i) memo = _memo;

        unchecked {
          ++i;
        }
      }

      if (_favoriteDelegate == type(uint256).max) delegate = defaultDelegate;
      if (_favoriteMemo == type(uint256).max) memo = defaultMemo;
    }
  }

  function redeemParams(JBRedeemParamsData calldata _param)
    external
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
