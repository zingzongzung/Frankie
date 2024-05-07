// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library NumberUtils {
	/**
	 *
	 * Used to get the number to multiply by the origin digit to create origin genes composed
	 *
	 * @param numDigits number of digits
	 */
	function closestPowerOfTen(uint numDigits) internal pure returns (uint) {
		if (numDigits <= 1) {
			return 1; // The closest power of ten to numbers with 1 or 0 digits is 1
		}

		uint power = 1;
		for (uint i = 1; i < numDigits; i++) {
			power *= 10;
		}
		return power;
	}

	function mapToRange(uint32 min, uint32 max, uint32 randomNumber) internal pure returns (uint32) {
		require(min < max, "Min must be less than max");

		// Calculate the range size
		uint32 rangeSize = max - min + 1;

		// Map randomNumber to the range size and add min to shift to the correct range
		uint32 mappedNumber = (randomNumber % rangeSize) + min;

		return mappedNumber;
	}

	function getNextGenePosition(uint8 currentPosition, uint8 treshold, uint8 digitCount) internal pure returns (uint8 genePosition) {
		if (currentPosition >= treshold) {
			genePosition = 0;
		} else {
			genePosition = currentPosition + digitCount;
		}
	}

	function extractDigits(uint number, uint8 position, uint8 digitCount, uint8 treshold) internal pure returns (uint32, uint8) {
		require(digitCount > 0, "Digit count must be greater than zero");

		// Calculate divisor to isolate desired digits
		uint divisor = 10 ** (position + digitCount);

		// Divide the number to isolate the desired digits
		uint32 extractedNumber = uint32((number % divisor) / (10 ** position));

		return (extractedNumber, getNextGenePosition(position, treshold, digitCount));
	}

	function countDigits(uint value) internal pure returns (uint8) {
		// Special case for the value zero
		if (value == 0) {
			return 1;
		}

		uint8 count = 0;
		while (value != 0) {
			count += 1;
			value /= 10;
		}

		return count;
	}

	// Example usage: Sum of all elements in an array
	function sum(uint8[] memory array) internal pure returns (uint8) {
		return reduce(array, add, 0);
	}

	function add(uint8 a, uint8 b) internal pure returns (uint8) {
		return a + b;
	}

	function reduce(uint8[] memory array, function(uint8, uint8) pure returns (uint8) reducer, uint8 initialValue) internal pure returns (uint8) {
		uint8 result = initialValue;
		for (uint8 i = 0; i < array.length; i++) {
			result = reducer(result, array[i]);
		}
		return result;
	}
}
