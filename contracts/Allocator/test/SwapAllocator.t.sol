// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './helpers/TestBaseWorkflow.sol';
import { SwapAllocator, IPoolWrapper } from '../example/swapAllocator/SwapAllocator.sol';

contract SwapAllocator_Test is TestBaseWorkflow {
  SwapAllocator _allocator;
  IPoolWrapper[] _dexes;
  address _tokenOut;
  address _poolWrapper1;
  address _poolWrapper2;
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
    _poolWrapper1 = makeAddr('_poolWrapper1');
    _poolWrapper2 = makeAddr('_poolWrapper2');
    _pool1 = makeAddr('_pool1');
    _pool2 = makeAddr('_pool2');
    _beneficiary =  payable(makeAddr('_beneficiary'));

    vm.etch(_poolWrapper1, new bytes(69));
    vm.etch(_poolWrapper2, new bytes(69));
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

    _dexes.push(IPoolWrapper(_poolWrapper1));
    _dexes.push(IPoolWrapper(_poolWrapper2));

    _allocator = new SwapAllocator( { _tokenOut: _tokenOut, _tokenIn: jbLibraries().ETHToken(), _dexes: _dexes });

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

  function test_allocate_distributeWithTwoPools(uint128 amount1, uint128 amount2) public {
    // Avoid silly overflow
    vm.assume(uint256(amount1) + uint256(amount2) <= type(uint128).max);
    vm.assume(amount1 != amount2);

    // The best amount out possible (either amount 1 or 2)
    uint128 _bestAmountOut = amount1 > amount2 ? amount1 : amount2;
    address _bestWrapper = amount1 > amount2 ? _poolWrapper1 : _poolWrapper2;

    // Mock the quote
    vm.mockCall(_poolWrapper1, abi.encodeCall(IPoolWrapper.getQuote, (1 ether, jbLibraries().ETHToken(), _tokenOut)), abi.encode(amount1, _pool1));
    vm.mockCall(_poolWrapper2, abi.encodeCall(IPoolWrapper.getQuote, (1 ether, jbLibraries().ETHToken(), _tokenOut)), abi.encode(amount2, _pool2));

    // Mock the actual swap
    vm.mockCall(
      _bestWrapper,
      abi.encodeCall(
        IPoolWrapper.swap,
        (1 ether, jbLibraries().ETHToken(), _tokenOut, _bestAmountOut, amount1 > amount2 ? _pool1 : _pool2)
      ),
      abi.encode(_bestAmountOut)
    );
    
    // Mock the transfer from the wrapper to the beneficiary
    vm.mockCall(_tokenOut, abi.encodeCall(IERC20.transferFrom, (_bestWrapper, _beneficiary, _bestAmountOut)), abi.encode(true));
   
    // --- Test ---

    // Check: call for a quote on every wrapper?
    vm.expectCall(_poolWrapper1, abi.encodeCall(IPoolWrapper.getQuote, (1 ether, jbLibraries().ETHToken(), _tokenOut)));
    vm.expectCall(_poolWrapper2, abi.encodeCall(IPoolWrapper.getQuote, (1 ether, jbLibraries().ETHToken(), _tokenOut)));

    if(_bestAmountOut != 0) {
      // Check: call to swap on the correct pool?  
      vm.expectCall(_bestWrapper, abi.encodeCall(IPoolWrapper.swap, (1 ether, jbLibraries().ETHToken(), _tokenOut, _bestAmountOut, amount1 > amount2 ? _pool1 : _pool2)));

      // Check: transfer the correct token to the beneficiary (if a swap was performed)?
      vm.expectCall(_tokenOut, abi.encodeCall(IERC20.transferFrom, (_bestWrapper, _beneficiary, _bestAmountOut)));
    }
    //else check eth balance (token out == token in)
    uint256 _balanceBefore = _beneficiary.balance;

    _terminal.distributePayoutsOf(_projectId, 1 ether, jbLibraries().ETH(), jbLibraries().ETHToken(), 0, 'payout');

    // If no swap, check eth balance
    if (_bestAmountOut == 0) assertEq(_balanceBefore + _beneficiary.balance, 1 ether);
  }

  function test_allocate_sendTokenInIfNoQuote(uint128 amountIn) public {
    vm.assume(amountIn <= 1 ether && amountIn != 0);

    // Mock the quote
    vm.mockCall(_poolWrapper1, abi.encodeCall(IPoolWrapper.getQuote, (amountIn, jbLibraries().ETHToken(), _tokenOut)), abi.encode(0, address(0)));
    vm.mockCall(_poolWrapper2, abi.encodeCall(IPoolWrapper.getQuote, (amountIn, jbLibraries().ETHToken(), _tokenOut)), abi.encode(0, address(0)));

    // --- Test ---

    // Check: call for a quote on every wrapper?
    vm.expectCall(_poolWrapper1, abi.encodeCall(IPoolWrapper.getQuote, (amountIn, jbLibraries().ETHToken(), _tokenOut)));
    vm.expectCall(_poolWrapper2, abi.encodeCall(IPoolWrapper.getQuote, (amountIn, jbLibraries().ETHToken(), _tokenOut)));

    //else check eth balance (token out == token in)
    uint256 _balanceBefore = _beneficiary.balance;

    _terminal.distributePayoutsOf(_projectId, amountIn, jbLibraries().ETH(), jbLibraries().ETHToken(), 0, 'payout');

    // No swap, check eth balance
    assertEq(_balanceBefore + _beneficiary.balance, amountIn);
  }

  function test_allocate_sendTokenInIfNoSwap(uint128 amountIn, uint128 amountOut1, uint128 amountOut2) public {
    vm.assume(amountIn <= 1 ether && amountIn != 0);

    vm.assume(uint256(amountOut1) + uint256(amountOut2) <= type(uint128).max);
    vm.assume(amountOut1 != amountOut2);

    // The best amount out possible (either amount 1 or 2)
    uint128 _bestAmountOut = amountOut1 > amountOut2 ? amountOut1 : amountOut2;
    address _bestWrapper = amountOut1 > amountOut2 ? _poolWrapper1 : _poolWrapper2;

    // Mock the quote
    vm.mockCall(_poolWrapper1, abi.encodeCall(IPoolWrapper.getQuote, (amountIn, jbLibraries().ETHToken(), _tokenOut)), abi.encode(amountOut1, _pool1));
    vm.mockCall(_poolWrapper2, abi.encodeCall(IPoolWrapper.getQuote, (amountIn, jbLibraries().ETHToken(), _tokenOut)), abi.encode(amountOut2, _pool2));

    // Mock the swap, returning 0
    vm.mockCall(
      _bestWrapper,
      abi.encodeCall(
        IPoolWrapper.swap,
        (amountIn, jbLibraries().ETHToken(), _tokenOut, _bestAmountOut, amountOut1 > amountOut2 ? _pool1 : _pool2)
      ),
      abi.encode(0)
    );

    // --- Test ---

    // Check: call for a quote on every wrapper?
    vm.expectCall(_poolWrapper1, abi.encodeCall(IPoolWrapper.getQuote, (amountIn, jbLibraries().ETHToken(), _tokenOut)));
    vm.expectCall(_poolWrapper2, abi.encodeCall(IPoolWrapper.getQuote, (amountIn, jbLibraries().ETHToken(), _tokenOut)));

    // Check: call to swap on the correct pool?  
    vm.expectCall(_bestWrapper, abi.encodeCall(IPoolWrapper.swap, (amountIn, jbLibraries().ETHToken(), _tokenOut, _bestAmountOut, amountOut1 > amountOut2 ? _pool1 : _pool2)));

    // But 0 token received, check eth balance (token out == token in)
    uint256 _balanceBefore = _beneficiary.balance;

    _terminal.distributePayoutsOf(_projectId, amountIn, jbLibraries().ETH(), jbLibraries().ETHToken(), 0, 'payout');

    // Check: no swap, check eth balance
    assertEq(_balanceBefore + _beneficiary.balance, amountIn);
  }

  // TODO: Test on revert
}
