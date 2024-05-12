// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ISurfForecastServiceConsumer.sol";
import "./SurfForecastService.sol";

abstract contract SurfForecastServiceConsumer is ISurfForecastServiceConsumer {
	SurfForecastService private surfForecastService;

	constructor(address surfForecastServiceAddress) {
		surfForecastService = SurfForecastService(surfForecastServiceAddress);
	}

	function sendRequest(address requestor) internal returns (bytes32 requestId) {
		return sendRequest(requestor);
	}
}
