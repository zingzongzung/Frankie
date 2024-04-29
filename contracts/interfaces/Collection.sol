// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Possible injection
// Unchecked Input: If the contract doesn't validate or sanitize input strings, it could be vulnerable to injection attacks. Always validate and sanitize user input before processing or storing it.
// Reentrancy: If the contract interacts with external contracts or sends transactions based on string input, it could be vulnerable to reentrancy attacks. Ensure that string input does not trigger unexpected behavior or interactions with other contracts.
// Limit Input Length: Limit the length of input strings to prevent buffer overflow or out-of-gas attacks. Use modifiers such as bytes or bytes32 to specify fixed-size string storage when possible.
// Use Secure Libraries: Utilize secure libraries and functions for string manipulation to minimize the risk of vulnerabilities. Avoid custom string manipulation logic unless necessary and thoroughly tested.
// Escape Special Characters: If the contract interacts with external systems or databases, properly escape or encode special characters to prevent injection attacks such as SQL injection.
// Audit Contracts: Regularly audit contract code for security vulnerabilities, including string handling vulnerabilities. Follow best practices and security guidelines recommended by the Ethereum community.

//NOTES: Change strings to bytes

//This Is the Abstract collection that must be implemented by the actual collection instance
abstract contract Collection {
	enum TraitType {
		Options,
		Number
	}

	//This represents all the collectionTraits
	uint8 traitsIndex;
	mapping(uint8 => string) traitLabels;
	mapping(uint8 => TraitType) atributeTypes;
	mapping(uint8 => uint8) traitChances; //Percentage between 0 and 99

	//Array Types
	mapping(uint8 => string[]) traitOptionLabels;
	mapping(uint8 => uint8[]) traitOptionChances;
	mapping(uint8 => string[]) traitOptionImages;

	//Number Types
	mapping(uint8 => uint32) traitNumberMin;
	mapping(uint8 => uint32) traitNumberMax;

	function addOptionsTrait(
		string memory traitLabel,
		uint8 traitChance,
		string[] memory valueLabels,
		uint8[] memory chances
	) external addBaseTrait(traitLabel, TraitType.Options, traitChance) {
		require(chances.length == valueLabels.length, "Invalid arrays");
		require(sum(chances) == 100);
		traitOptionChances[traitsIndex] = chances;
		traitOptionLabels[traitsIndex] = valueLabels;
	}

	function addOptionsWithImageTrait(
		string memory traitLabel,
		uint8 traitChance,
		string[] memory valueLabels,
		uint8[] memory chances,
		string[] memory images
	) external addBaseTrait(traitLabel, TraitType.Options, traitChance) {
		require(chances.length == valueLabels.length, "Invalid arrays");
		require(sum(chances) == 100);
		traitOptionChances[traitsIndex] = chances;
		traitOptionLabels[traitsIndex] = valueLabels;
		traitOptionImages[traitsIndex] = images;
	}

	function addNumberTrait(string memory traitLabel, uint8 traitChance, uint8 min, uint8 max) external addBaseTrait(traitLabel, TraitType.Number, traitChance) {
		require(min <= max, "Min should be less than max");
		traitNumberMin[traitsIndex] = min;
		traitNumberMax[traitsIndex] = max;
	}

	modifier addBaseTrait(
		string memory traitLabel,
		TraitType traitType,
		uint8 traitChance
	) {
		traitLabels[traitsIndex] = traitLabel;
		atributeTypes[traitsIndex] = traitType;
		traitChances[traitsIndex] = traitChance - 1; //0 will represent 1% and 99 100%
		_;
		traitsIndex++;
	}

	function getTraitNumberConfig(uint8 traitKeyId) external view returns (uint32 min, uint32 max) {
		return (traitNumberMin[traitKeyId], traitNumberMax[traitKeyId]);
	}

	function getTraitOptionLabel(uint8 traitKeyId, uint8 traitId) external view returns (string memory) {
		return traitOptionLabels[traitKeyId][traitId];
	}

	function getTraitOptionChance(uint8 traitKeyId, uint8 traitId) external view returns (uint8) {
		return traitOptionChances[traitKeyId][traitId];
	}

	function getTraitOptionImage(uint8 traitKeyId, uint8 traitId) external view returns (string memory result) {
		if (traitOptionImages[traitKeyId].length == 0) {
			result = "";
		} else {
			result = traitOptionImages[traitKeyId][traitId];
		}
	}

	function getNumberOfTraits() external view returns (uint8 numberOfTraits) {
		return traitsIndex;
	}

	function getTraitOptionChances(uint8 traitKeyId) external view returns (uint8[] memory) {
		return traitOptionChances[traitKeyId];
	}

	function getTraitLabel(uint8 traitKeyId) external view returns (string memory) {
		return traitLabels[traitKeyId];
	}

	function getTraitKeyType(uint8 traitKeyId) external view returns (TraitType) {
		return atributeTypes[traitKeyId];
	}

	function getTraitChance(uint8 traitKeyId) external view returns (uint8) {
		return traitChances[traitKeyId];
	}

	//helpers

	// Example usage: Sum of all elements in an array
	function sum(uint8[] memory array) public pure returns (uint8) {
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
