// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAutomationManager {
	function registerUpkeep(address requestor, uint actionRequested) external;
}
