// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Strings.sol";

library Utils {
	// Function to convert address to string
	function addressToString(address _address) internal pure returns (string memory) {
		return Strings.toHexString(_address);
	}
}
