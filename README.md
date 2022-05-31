# juice-data-source

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

- contracts/DataSourceDelegate.sol and contracts/ETHTerminal.sol contains canevas for datasource/pay&redeem delegate and terminal
- contracts/collection/ provide a set of ready made delegates, datasources and terminals
  -- NFT/: A datasource minting a NFT for every contribution and a redemption delegate preventing redemption for non-NFT holder ("closed-loop treasury")
  -- payment routing/: A datasource-delegate following the best possible route between minting and token buy on secondary market, in order to maximise the amount of token received by the contributor.

## Tests

Test for every extension are provided in contracts/test. Those test are using a complete Juicebox contracts deployment (provided in helpers/TestBaseWorkflow) without requiring a forked network.

## Deploy

Refer to the [Foundry Book](https://book.getfoundry.sh/forge/deploying.html) on deploying for advanced use.

Example of deployment and etherscan verification:

```bash
forge create --rpc-url RPC_NODE_URL -i --verify --constructor-args "FOO" 123 "BAR"
```
