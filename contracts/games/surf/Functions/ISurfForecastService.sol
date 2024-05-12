// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ISurfForecastService {
	function sendRequest(address requestor) external returns (bytes32 requestId);
}
