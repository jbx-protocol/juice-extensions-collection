//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

interface ICurveRegistry {
  function find_pool_for_coins(
    address _from,
    address _to,
    uint256 i
  ) external view returns (address pool);

  function get_coin_indices(
    address pool,
    address _from,
    address _to
  )
    external
    view
    returns (
      int128,
      int128,
      bool
    );
}
