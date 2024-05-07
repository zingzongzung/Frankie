// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../libraries/Types.sol";

interface IAutomationCallback {
	function executeAction(uint action) external;
}
