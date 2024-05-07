// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IAutomationCallback.sol";
import "./IAutomationManager.sol";
import "../../libraries/Roles.sol";

contract AutomationManager is IAutomationManager, AutomationCompatibleInterface, AccessControl, ReentrancyGuard {
	/**
	 * Use an interval in seconds and a timestamp to slow execution of Upkeep
	 */
	uint256 public immutable interval;
	uint256 public lastTimeStamp;
	uint8 public maxIterations;

	bool isUpkeepNeeded;

	struct AutomationManagerRequest {
		address requestor;
		uint actionRequested;
	}

	uint immutable MAX_PENDING_REQUESTS = 3;

	uint currentRequestProcessing;
	uint requestsLength;
	mapping(uint => AutomationManagerRequest) private requests;

	//AutomationManagerRequest[] private requests;

	constructor(uint256 updateInterval, uint8 _maxIterations) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		interval = updateInterval;
		lastTimeStamp = block.timestamp;
		maxIterations = _maxIterations;
	}

	// function getRequests() external view returns (AutomationManagerRequest[] memory) {
	// 	return requests;
	// }

	function registerUpkeep(address requestor, uint actionRequested) external override onlyRole(Roles.AUTOMATION_MANAGER) {
		AutomationManagerRequest memory automationRequest = AutomationManagerRequest(requestor, actionRequested);
		isUpkeepNeeded = true;

		requests[requestsLength] = automationRequest;
		requestsLength++;
	}

	function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
		upkeepNeeded = isUpkeepNeeded;
	}

	function performUpkeep(bytes calldata /* performData */) external override {
		uint8 currentIteration = 0;

		bool hasNext = _hasNext();
		while (hasNext && currentIteration < maxIterations) {
			AutomationManagerRequest memory request = getNext();
			//Call Action executors on requestors
			IAutomationCallback automationCallback = IAutomationCallback(request.requestor);
			automationCallback.executeAction(request.actionRequested);
			//Process Queue
			hasNext = _hasNext();
			currentIteration++;
		}
	}

	function getNext() internal returns (AutomationManagerRequest memory request) {
		if (requestsLength > 0) {
			request = requests[currentRequestProcessing];
			currentRequestProcessing++;
		}
	}

	function _hasNext() internal view returns (bool) {
		return requestsLength > 0 && currentRequestProcessing < requestsLength;
	}
}
