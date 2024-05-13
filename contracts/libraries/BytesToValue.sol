// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

library BytesToValue {
	function toUint_Dynamic(bytes memory dataBytes, uint256 startPos) internal pure returns (uint32 result, uint256 endPosition) {
		uint length = getLength(dataBytes, startPos);
		startPos++;
		return (toUint(slice(dataBytes, startPos, length)), startPos + length);
	}

	function toBool(bytes memory dataBytes, uint256 startPos) internal pure returns (bool result, uint256 endPosition) {
		uint256 length = 1;
		return (toBool(slice(dataBytes, startPos, length)), startPos + length);
	}

	function getLength(bytes memory dataBytes, uint256 startPos) internal pure returns (uint256 length) {
		length = toUint(slice(dataBytes, startPos, 1));
	}

	// Converts bytes to uint
	function toUint(bytes memory b) internal pure returns (uint32) {
		uint32 number;
		for (uint i = 0; i < b.length; i++) {
			number = number * 10 + (uint8(b[i]) - 48); // ASCII conversion
		}
		return number;
	}

	// Converts bytes to bool
	function toBool(bytes memory b) internal pure returns (bool) {
		return b[0] == "1";
	}

	// Slice bytes array
	function slice(bytes memory data, uint start, uint length) internal pure returns (bytes memory) {
		bytes memory part = new bytes(length);
		for (uint i = 0; i < length; i++) {
			part[i] = data[i + start];
		}
		return part;
	}
}
