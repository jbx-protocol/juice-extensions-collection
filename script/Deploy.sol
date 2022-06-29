pragma solidity 0.8.6;

import 'forge-std/Test.sol';

contract DeployMainnet is Test {
  function run() external {
    vm.startBroadcast();

    // myContract = new Contract(foo, bar);
  }
}

contract DeployRinkeby is Test {
  function run() external {
    vm.startBroadcast();

    // myContract = new Contract(foo, bar);
  }
}
