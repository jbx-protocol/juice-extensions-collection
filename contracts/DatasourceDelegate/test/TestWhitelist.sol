// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './helpers/TestBaseWorkflow.sol';
import '../examples/whitelist/WhitelistDataSource.sol';

import '@jbx-protocol-v2/contracts/interfaces/IJBFundingCycleDataSource.sol';

contract TestWhitelist is TestBaseWorkflow {
  JBController private _controller;
  JBETHPaymentTerminal private _terminal;
  JBTokenStore private _tokenStore;

  JBProjectMetadata private _projectMetadata;
  JBFundingCycleData private _data;
  JBFundingCycleMetadata private _metadata;
  JBGroupedSplits[] private _groupedSplits; // Default empty
  JBFundAccessConstraints[] private _fundAccessConstraints; // Default empty
  IJBPaymentTerminal[] private _terminals; // Default empty

  uint256 private _projectId;
  address private _projectOwner;
  uint256 private _weight = 1000 * 10**18;
  uint256 private _targetInWei = 10 * 10**18;

  WhitelistDataSource whitelistDatasource;

  event AddToWhitelist(uint256 numberOfAddresses);
  event RemoveFromWhitelist(uint256 numberOfAddresses);

  function setUp() public override {
    super.setUp();

    whitelistDatasource = new WhitelistDataSource(jbProjects(), 1); /*projectid jbproject*/

    _controller = jbController();

    _terminal = jbETHPaymentTerminal();

    _tokenStore = jbTokenStore();

    _projectMetadata = JBProjectMetadata({content: 'myIPFSHash', domain: 1});

    _data = JBFundingCycleData({
      duration: 14,
      weight: _weight,
      discountRate: 450000000,
      ballot: IJBFundingCycleBallot(address(0))
    });

    _metadata = JBFundingCycleMetadata({
      global: JBGlobalFundingCycleMetadata({allowSetTerminals: false, allowSetController: false}),
      reservedRate: 0,
      redemptionRate: 10000, //100%
      ballotRedemptionRate: 0,
      pausePay: false,
      pauseDistributions: false,
      pauseRedeem: false,
      pauseBurn: false,
      allowMinting: false,
      allowChangeToken: false,
      allowTerminalMigration: false,
      allowControllerMigration: false,
      holdFees: false,
      useTotalOverflowForRedemptions: false,
      useDataSourceForPay: true,
      useDataSourceForRedeem: true,
      dataSource: address(whitelistDatasource)
    });

    _terminals.push(_terminal);

    _fundAccessConstraints.push(
      JBFundAccessConstraints({
        terminal: _terminal,
        token: jbLibraries().ETHToken(),
        distributionLimit: _targetInWei, // 10 ETH target
        overflowAllowance: 5 ether,
        distributionLimitCurrency: 1, // Currency = ETH
        overflowAllowanceCurrency: 1
      })
    );

    _projectOwner = multisig();

    _projectId = _controller.launchProjectFor(
      _projectOwner,
      _projectMetadata,
      _data,
      _metadata,
      block.timestamp,
      _groupedSplits,
      _fundAccessConstraints,
      _terminals,
      ''
    );
  }

  // -- AddToWhitelist --

  function testAddToWhitelist_addOneAddressIfCallerIsProjectOwner(
    address _whitelistedAddress,
    address _nonWhitelistedAddress
  ) external {
    vm.assume(_whitelistedAddress != _nonWhitelistedAddress);
    vm.prank(_projectOwner);

    // Emit correct event?
    vm.expectEmit(false, false, false, true);
    emit AddToWhitelist(1);

    whitelistDatasource.addToWhitelist(_whitelistedAddress);

    // Check: is whitelisted and a non-whitelisted isn't, by default
    assertEq(whitelistDatasource.isWhitelisted(_whitelistedAddress), true);
    assertEq(whitelistDatasource.isWhitelisted(_nonWhitelistedAddress), false);
  }

  function testAddToWhitelist_addMultipleAddressesIfCallerIsProjectOwner(uint8 numberOfAddresses)
    external
  {
    vm.assume(numberOfAddresses < 200);
    address[] memory _addressesToAdd = new address[](numberOfAddresses);
    for (uint256 i; i < numberOfAddresses; i++)
      _addressesToAdd[i] = address(bytes20(keccak256(abi.encode(i))));

    vm.prank(_projectOwner);

    // Emit correct event?
    vm.expectEmit(false, false, false, true);
    emit AddToWhitelist(numberOfAddresses);

    whitelistDatasource.addToWhitelist(_addressesToAdd);

    // Check: all the addresses are now whitelisted
    for (uint256 i; i < numberOfAddresses; i++)
      assertEq(whitelistDatasource.isWhitelisted(_addressesToAdd[i]), true);
  }

  function testAddToWhitelist_revertIfCallerIsNotProjectOwner(
    address _whitelistedAddress,
    address _caller
  ) external {
    vm.assume(_caller != _projectOwner);
    vm.prank(_caller);

    vm.expectRevert(abi.encodeWithSignature('WhitelistDataSource_Unauthorised()'));
    whitelistDatasource.addToWhitelist(_whitelistedAddress);

    // Check: still not whitelisted
    assertEq(whitelistDatasource.isWhitelisted(_whitelistedAddress), false);
  }

  // -- removeFromWhitelist --

  function testRemoveFromWhitelist_removeOneAddressIfCallerIsProjectOwner(
    address _whitelistedAddress
  ) external {
    vm.prank(_projectOwner);
    whitelistDatasource.addToWhitelist(_whitelistedAddress);

    // Sqnity check
    assertEq(whitelistDatasource.isWhitelisted(_whitelistedAddress), true);

    // Emit correct event?
    vm.expectEmit(false, false, false, true);
    emit RemoveFromWhitelist(1);

    vm.prank(_projectOwner);
    whitelistDatasource.removeFromWhitelist(_whitelistedAddress);

    // Check: is whitelisted and a non-whitelisted isn't, by default
    assertEq(whitelistDatasource.isWhitelisted(_whitelistedAddress), false);
  }

  function testRemoveFromWhitelist_removeMultipleAddressesIfCallerIsProjectOwner(
    uint8 numberOfAddresses
  ) external {
    // Set the addresses
    vm.assume(numberOfAddresses < 200);
    address[] memory _addressesToAdd = new address[](numberOfAddresses);
    for (uint256 i; i < numberOfAddresses; i++)
      _addressesToAdd[i] = address(bytes20(keccak256(abi.encode(i))));

    vm.prank(_projectOwner);
    whitelistDatasource.addToWhitelist(_addressesToAdd);

    // Sanity check: all the addresses are now whitelisted
    for (uint256 i; i < numberOfAddresses; i++)
      assertEq(whitelistDatasource.isWhitelisted(_addressesToAdd[i]), true);

    // Emit correct event?
    vm.expectEmit(false, false, false, true);
    emit RemoveFromWhitelist(numberOfAddresses);

    vm.prank(_projectOwner);
    whitelistDatasource.removeFromWhitelist(_addressesToAdd);

    // Check: is whitelisted and a non-whitelisted isn't, by default
    for (uint256 i; i < numberOfAddresses; i++)
      assertEq(whitelistDatasource.isWhitelisted(_addressesToAdd[i]), false);
  }

  function testRemoveFromWhitelist_revertIfCallerIsNotProjectOwner(
    address _caller,
    address _whitelistedAddress
  ) external {
    vm.assume(_caller != _projectOwner);

    vm.prank(_projectOwner);
    whitelistDatasource.addToWhitelist(_whitelistedAddress);

    // Sanity check
    assertEq(whitelistDatasource.isWhitelisted(_whitelistedAddress), true);

    vm.prank(_caller);
    vm.expectRevert(abi.encodeWithSignature('WhitelistDataSource_Unauthorised()'));
    whitelistDatasource.removeFromWhitelist(_whitelistedAddress);

    assertEq(whitelistDatasource.isWhitelisted(_whitelistedAddress), true);
  }

  // -- payParams --

  function testPayParams_returnCorrectWeightIfBeneficiaryIsWhitelisted(
    address _whitelistedAddress,
    uint256 _whitelistWeight,
    string memory _whitelistMemo
  ) external {
    vm.prank(_projectOwner);
    whitelistDatasource.addToWhitelist(_whitelistedAddress);

    // Sanity check
    assertEq(whitelistDatasource.isWhitelisted(_whitelistedAddress), true);

    JBPayParamsData memory _payParamsData = JBPayParamsData({
      terminal: IJBPaymentTerminal(msg.sender),
      payer: address(666),
      amount: JBTokenAmount({token: address(0), value: 10 ether, decimals: 18, currency: 1}),
      projectId: _projectId,
      currentFundingCycleConfiguration: block.timestamp,
      beneficiary: _whitelistedAddress,
      weight: _whitelistWeight,
      reservedRate: 0,
      memo: _whitelistMemo,
      metadata: new bytes(0)
    });

    (
      uint256 _returnedWeight,
      string memory _returnedMemo,
      IJBPayDelegate _delegate
    ) = whitelistDatasource.payParams(_payParamsData);

    assertEq(_returnedWeight, _whitelistWeight);
    assertEq(_returnedMemo, _whitelistMemo);
    assertEq(address(_delegate), address(0));
  }

  function testPayParams_revertIfBeneficiaryIsNotWhitelisted(
    address _whitelistedAddress,
    uint256 _whitelistWeight,
    string memory _whitelistMemo
  ) external {
    // Sanity check
    assertEq(whitelistDatasource.isWhitelisted(_whitelistedAddress), false);

    JBPayParamsData memory _payParamsData = JBPayParamsData({
      terminal: IJBPaymentTerminal(msg.sender),
      payer: address(666),
      amount: JBTokenAmount({token: address(0), value: 10 ether, decimals: 18, currency: 1}),
      projectId: _projectId,
      currentFundingCycleConfiguration: block.timestamp,
      beneficiary: _whitelistedAddress,
      weight: _whitelistWeight,
      reservedRate: 0,
      memo: _whitelistMemo,
      metadata: new bytes(0)
    });

    vm.expectRevert(abi.encodeWithSignature('WhitelistDataSource_BeneficiaryNotWhitelisted()'));
    (
      uint256 _returnedWeight,
      string memory _returnedMemo,
      IJBPayDelegate _delegate
    ) = whitelistDatasource.payParams(_payParamsData);
  }
}
