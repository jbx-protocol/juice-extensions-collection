// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './helpers/TestBaseWorkflow.sol';
import { SwapAllocator, IPoolWrapper } from '../example/swapAllocator/SwapAllocator.sol';

contract SwapAllocator_e2eTest is TestBaseWorkflow {
  SwapAllocator _allocator;
  IPoolWrapper[] _dexes;
  address _tokenOut;
  address _pool1;
  address _pool2;
  address payable _beneficiary;

  JBController _controller;
  JBETHPaymentTerminal _terminal;
  JBTokenStore _tokenStore;
  
  JBProjectMetadata _projectMetadata;
  JBFundingCycleData _data;
  JBFundingCycleMetadata _metadata;
  JBFundAccessConstraints[] _fundAccessConstraints;
  IJBPaymentTerminal[] _terminals;

  uint256 _projectId;
  address _projectOwner;
  uint256 _weight = 1000 * 10**18;
  uint256 _targetInWei = 10 * 10**18;

  function setUp() public override {
    super.setUp();

    JBSplit[] memory _splits = new JBSplit[](1);
    JBGroupedSplits[] memory  _groupedSplits = new JBGroupedSplits[](1);

    _tokenOut = makeAddr('_tokenOut');
    _pool1 = makeAddr('_pool1');
    _pool2 = makeAddr('_pool2');
    _beneficiary =  payable(makeAddr('_beneficiary'));

    vm.etch(_pool1, new bytes(69));
    vm.etch(_pool2, new bytes(69));

    _controller = jbController();
    _terminal = jbETHPaymentTerminal();
    _tokenStore = jbTokenStore();

    _projectMetadata = JBProjectMetadata({content: 'myIPFSHash', domain: 1});
    _data = JBFundingCycleData({
      duration: 0,
      weight: _weight,
      discountRate: 450000000,
      ballot: IJBFundingCycleBallot(address(0))
    });

    _metadata = JBFundingCycleMetadata({
      global: JBGlobalFundingCycleMetadata({
        allowSetTerminals: false,
        allowSetController: false,
        pauseTransfers: false
      }),
      reservedRate: 0, 
      redemptionRate: 10000,
      ballotRedemptionRate: 0,
      pausePay: false,
      pauseDistributions: false,
      pauseRedeem: false,
      pauseBurn: false,
      allowMinting: false,
      allowTerminalMigration: false,
      allowControllerMigration: false,
      holdFees: false,
      preferClaimedTokenOverride: false,
      useTotalOverflowForRedemptions: false,
      useDataSourceForPay: true,
      useDataSourceForRedeem: true,
      dataSource: address(0),
      metadata: 0
    });

    evm.prank(multisig());
    _terminal.setFee(0);

    _terminals.push(_terminal);

    _fundAccessConstraints.push(
      JBFundAccessConstraints({
        terminal: _terminal,
        token: jbLibraries().ETHToken(),
        distributionLimit: 10 ether,
        overflowAllowance: 10 ether,
        distributionLimitCurrency: 1, // Currency = ETH
        overflowAllowanceCurrency: 1
      })
    );

    _projectOwner = multisig();

    _dexes.push(IPoolWrapper(_pool1));
    _dexes.push(IPoolWrapper(_pool2));

    _allocator = new SwapAllocator(_tokenOut, _dexes);

    _splits[0] = JBSplit({
      preferClaimed: true,
      preferAddToBalance: false,
      percent: JBConstants.SPLITS_TOTAL_PERCENT,
      projectId: 1,
      beneficiary: _beneficiary,
      lockedUntil: 0,
      allocator: _allocator // allocator should prevail on beneficiary and projectId
    });

    _groupedSplits[0] = JBGroupedSplits({ group: 1, splits: _splits });

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

    _terminal.pay{value: 10 ether}(
      _projectId,
      10 ether,
      address(0),
      _beneficiary,
      /* _minReturnedTokens */
      0,
      /* _preferClaimedTokens */
      false,
      /* _memo */
      'Take my money!',
      /* _delegateMetadata */
      new bytes(0)
    );
  }

  /**
    @dev Should swap using the _pool2 as it returns 1 more token
  */
  function test_distributeWithTwoPools() public {
    vm.mockCall(_pool1, abi.encodeCall(IPoolWrapper.getQuote, (1 ether, jbLibraries().ETHToken(), _tokenOut)), abi.encode(100, _pool1));
    vm.mockCall(_pool2, abi.encodeCall(IPoolWrapper.getQuote, (1 ether, jbLibraries().ETHToken(), _tokenOut)), abi.encode(101, _pool2));

    vm.mockCall(_pool1, abi.encodeCall(IPoolWrapper.getQuote, (1 ether, jbLibraries().ETHToken(), _tokenOut)), abi.encode(100, _pool1));


    _terminal.distributePayoutsOf(_projectId, 1 ether, jbLibraries().ETH(), jbLibraries().ETHToken(), 0, 'payout');
  }


}
