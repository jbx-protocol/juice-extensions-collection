// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@jbx-protocol-v2/contracts/interfaces/IJBFundingCycleDataSource.sol';
import '@jbx-protocol-v2/contracts/interfaces/IJBProjects.sol';

/**
  @title
  Juicebox Datasource for simple whitelisting

  @notice
  This is a datasource handeling a mapping of whitelisted addresses. The project owner should add
  addresses to this datasource using addToWhitelist. This is a simple imlpementation (using a mapping),
  for bigger whitelist, a more gas-efficient solution might be better (eg merkle tree)

  @dev
  Access is controlled at add/remove whitelist addresses level, the delegate can be reused if another
  project wants the same set of whitelisted addresses.
*/
contract WhitelistDataSource is IJBFundingCycleDataSource {
  IJBProjects immutable jbProjects;

  uint256 immutable projectId;

  /**
    @dev Throws if a non-whitelisted beneficiary trie to pay
  */
  error WhitelistDataSource_BeneficiaryNotWhitelisted();

  /**
    @dev   emit when adding addresses to the whitelist
    @param numberOfAddresses the number of addresses, if an array was passed
  */
  event AddToWhitelist(uint256 numberOfAddresses);

  /**
    @dev   emit when removing addresses to the whitelist
    @param numberOfAddresses the number of addresses, if an array was passed
  */
  event RemoveFromWhitelist(uint256 numberOfAddresses);

  /**
    @notice the whitelisted addresses, true if whitelisted
  */
  mapping(address => bool) public isWhitelisted;

  /**
    @notice Only the holder of the project NFT can execute the function (used for the whitelist management)
  */
  modifier onlyProjectOwner(uint256 _projectId) {
    if (msg.sender != jbProjects.ownerOf(_projectId)) revert WhitelistDataSource_Unauthorised();
    _;
  }

  /**
    @param _jbProjects the JBProjects contracts deployment
    @param _projectId the id of the project (the holder of the corresponding NFT has access to add/remove address)
  */
  constructor(IJBProjects _jbProjects, uint256 _projectId) {
    jbProjects = _jbProjects;
    projectId = _projectId;
  }

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
    // Revert if beneficiary is non whitelisted
    if (!isWhitelisted[_data.beneficiary]) revert WhitelistDataSource_BeneficiaryNotWhitelisted();

    // If disabling non-whitelisted payer too, uncomment the following:
    // if (!isWhitelisted[_data.payer]) revert WhitelistDataSource_BeneficiaryNotWhitelisted();

    return (_data.weight, _data.memo, IJBPayDelegate(address(0)));
  }

  /**
    @notice  Add an array of addresses to the whitelist
    @dev     the previous whitelist status is not read, for gas optimisation
    @param   addresses the addresses to whitelist
  */
  function addToWhitelist(address[] calldata addresses) onlyProjectOwner {
    uint256 numberOfAddresses = addresses.length; // Push to stack
    for (uint256 i; i < numberOfAddresses; ) {
      isWhitelisted[addresses[i]] = true;
      unchecked {
        ++i;
      }
    }
    emit AddToWhitelist(numberOfAddresses); // Not passing the whole array for gas reason
  }

  /**
    @notice  Add a single address to the whitelist
    @param   _address the address to whitelist
  */
  function addToWhitelist(address _address) onlyProjectOwner {
    isWhitelisted[_address] = true;
    emit AddToWhitelist(1);
  }

  /**
    @notice  Remove an array of addresses from the whitelist
    @dev     the previous whitelist status is not read, for gas optimisation
    @param   addresses the addresses to remove from the whitelist
  */
  function removeFromWhitelist(address[] calldata addresses) external onlyProjectOwner {
    uint256 numberOfAddresses = addresses.length; // Push to stack
    for (uint256 i; i < numberOfAddresses; ) {
      delete isWhitelisted[addresses[i]];
      unchecked {
        ++i;
      }
    }
    emit RemoveFromWhitelist(numberOfAddresses);
  }

  /**
    @notice  Remove a single address from the whitelist
    @dev     the previous whitelist status is not read, for gas optimisation
    @param   _address the addresses to remove from the whitelist
  */
  function removeFromWhitelist(address _address) external onlyProjectOwner {
    delete isWhitelisted[_address];
    emit RemoveFromWhitelist(1);
  }

  function supportsInterface(bytes4 _interfaceId) external pure override returns (bool) {
    return _interfaceId == type(IJBFundingCycleDataSource).interfaceId;
  }

  //@dev unused, for interface completion only
  //@inheritdocs IJBFundingCycleDataSource
  function redeemParams(JBRedeemParamsData calldata _data)
    external
    view
    override
    returns (
      uint256 reclaimAmount,
      string memory memo,
      IJBRedemptionDelegate delegate
    )
  {
    return (_data.reclaimAmount.value, _data.memo, IJBRedemptionDelegate(address(0)));
  }
}
