//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;

interface IAnyswapV4Router {
	function anySwapOutUnderlying(
		address token,
		address to,
		uint amount,
		uint toChainID
	) external;
}