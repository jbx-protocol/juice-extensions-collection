// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol';

import '@openzeppelin/contracts/interfaces/IERC721.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 @dev Datasource example, not modifiying the weight while pay is triggered but 
      returning a weight of 0 while redeeming, if the caller is not an NFT holder
*/

contract NFTFundingCycleDataSource is IJBFundingCycleDataSource, ERC165 {
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
    if (IERC721(address(NFTDelegate)).balanceOf(_param.holder) > 0)
      return (_param.reclaimAmount.value, 'bye holder', IJBRedemptionDelegate(address(0)));
    else return (0, 'no way', IJBRedemptionDelegate(address(0)));
  }

  function supportsInterface(bytes4 _interfaceId)
    public
    view
    override(IERC165, ERC165)
    returns (bool)
  {
    return
      _interfaceId == type(IJBFundingCycleDataSource).interfaceId ||
      _interfaceId == type(IJBPayDelegate).interfaceId ||
      _interfaceId == type(IJBRedemptionDelegate).interfaceId ||
      super.supportsInterface(_interfaceId);
  }
}
