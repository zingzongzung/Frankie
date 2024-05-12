// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISurfForecastServiceConsumer {
	function handleForecastServiceResponse(bytes32 requestId, bytes memory response) external;
}
