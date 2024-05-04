// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MockAggregatorAVAX_USD is AggregatorV3Interface {
	function decimals() external view override returns (uint8) {}

	function description() external view override returns (string memory) {}

	function version() external view override returns (uint256) {}

	function getRoundData(uint80 _roundId) external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {}

	function latestRoundData() external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
		return (0, 3351772906, 0, 0, 0);
	}
}
