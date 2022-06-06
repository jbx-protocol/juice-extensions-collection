# juice-data-source

## Notice

This repo provides some implementation templates of peripheral contracts of the Juicebox V2 ecosystem, as well as some common implementation as examples.

## Installation

This repo is powered by Forge. To install the latest version, follow the [instructions](https://github.com/foundry-rs/foundry):

1. Install [Foundry](https://github.com/gakonst/foundry).

```bash
curl -L https://foundry.paradigm.xyz | sh
```

2. Update to the latest version

```bash
foundryup
```

3. Install external libs

```bash
git submodule update --init
```

Resources:

- [The Forge-Book](https://book.getfoundry.sh)

## Content

This repo is organised as follow:

- contracts/Allocator: contains an IJBSplitsAllocator implementation template (Allocator.sol) as well as existing implementions, in contracts/Allocator/examples:
  -- SunsetAllocator.sol: an allocator providing custom sunsets (a timestamp after which a reccuring payment is not made anymore) to each beneficiaries of a group of splits

- contracts/DatasourceDelegate: contains an IJBFundingCycleDataSource, IJBPayDelegate and IJBRedemptionDelegate implementation templates (DataSourceDelegate.sol) as well as existing implementions, in contracts/Allocator/examples:
  -- NFT directory: a datasource minting a NFT for every contribution and a redemption delegate preventing redemption for non-NFT holder ("closed-loop treasury")
  -- payment routing/: A datasource-delegate following the best possible route between minting and token buy on secondary market, in order to maximise the amount of token received by the contributor.

- contracts/Terminal: contains an IJBPaymentTerminal and IJBRedemptionTerminal implementation template.

## Tests

Test for every extension are provided in contracts/test. Those test are using a complete Juicebox contracts deployment (provided in helpers/TestBaseWorkflow) without requiring a forked network.

## Deploy

Refer to the [Foundry Book](https://book.getfoundry.sh/forge/deploying.html) on deploying for advanced use.

Example of deployment and etherscan verification:

```bash
forge create --rpc-url RPC_NODE_URL -i --verify --constructor-args "FOO" 123 "BAR"
```
