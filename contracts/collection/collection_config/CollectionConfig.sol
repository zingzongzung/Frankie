// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ICollectionConfig.sol";
import "../../libraries/Generator.sol";
import "../../managers/nfts/PassManager.sol";

contract CollectionConfig is ICollectionConfig {
	//Collection attributes
	uint256 private collectionPrice;
	uint16 private svgBoxHeight;
	uint16 private svgBoxWidth;

	//This represents all the collectionTraits that can be part of an NFT
	uint8 traitsLength;
	mapping(uint8 => string) traitLabels;
	mapping(uint8 => Types.TraitType) atributeTypes;
	mapping(uint8 => uint8) traitChances; //Percentage between 0 and 99

	//Array Types
	mapping(uint8 => string[]) traitOptionLabels;
	mapping(uint8 => uint8[]) traitOptionChances;
	mapping(uint8 => string[]) traitOptionImages;

	//Number Types
	mapping(uint8 => uint32) traitNumberMin;
	mapping(uint8 => uint32) traitNumberMax;

	//Indexing
	mapping(string => uint8) traitKeysByName;
	mapping(uint8 => uint8) traitKeysByIndex;

	//IERC7496 compatibility
	mapping(bytes32 => uint8) traitKeyIndex;

	Types.Pass pass;
	PassManager passManager;

	bool isCollectionClosed;

	constructor(address passManagerAddress, address passAddress, uint passId, bytes32 originalMessage, bytes memory signature) {
		passManager = PassManager(passManagerAddress);
		passManager.isAuthorized(passAddress, passId, originalMessage, signature);
		isCollectionClosed = false;
		pass = Types.Pass(passAddress, passId);
		passManager.setPassUsed(passAddress, passId);
	}

	function closeCollection() external {
		//Calculate hash in a similiar way that was calculated by the front end
		isCollectionClosed = true;
	}

	function setCollectionAttributes(uint256 _collectionPrice, uint16 _svgBoxHeight, uint16 _svgBoxWidth) external {
		collectionPrice = _collectionPrice;
		svgBoxHeight = _svgBoxHeight;
		svgBoxWidth = _svgBoxWidth;
	}

	function getCollectionAttributes() external view returns (uint256 _collectionPrice, uint16 _svgBoxHeight, uint16 _svgBoxWidth) {
		return (collectionPrice, svgBoxHeight, svgBoxWidth);
	}

	function addOptionsTrait(
		uint8 traitKey,
		string memory traitLabel,
		uint8 traitChance,
		string[] memory valueLabels,
		uint8[] memory chances
	) external addBaseTrait(traitKey, traitLabel, Types.TraitType.Options, traitChance) {
		require(chances.length == valueLabels.length, "Invalid arrays");
		require(sum(chances) == 100);
		traitOptionChances[traitKey] = chances;
		traitOptionLabels[traitKey] = valueLabels;
	}

	function addOptionsWithImageTrait(
		uint8 traitKey,
		string memory traitLabel,
		uint8 traitChance,
		string[] memory valueLabels,
		uint8[] memory chances,
		string[] memory images
	) external addBaseTrait(traitKey, traitLabel, Types.TraitType.OptionsWithImage, traitChance) {
		require(chances.length == valueLabels.length, "Invalid arrays");
		require(sum(chances) == 100);
		traitOptionChances[traitKey] = chances;
		traitOptionLabels[traitKey] = valueLabels;
		traitOptionImages[traitKey] = images;
	}

	function addNumberTrait(
		uint8 traitKey,
		string memory traitLabel,
		uint8 traitChance,
		uint8 min,
		uint8 max
	) external addBaseTrait(traitKey, traitLabel, Types.TraitType.Number, traitChance) {
		require(min <= max, "Min should be less than max");
		traitNumberMin[traitKey] = min;
		traitNumberMax[traitKey] = max;
	}

	modifier addBaseTrait(
		uint8 traitKey,
		string memory traitLabel,
		Types.TraitType traitType,
		uint8 traitChance
	) {
		require(traitChance > 0 && traitChance <= 100, "Chance must be a positive number less than 100");
		traitLabels[traitKey] = traitLabel;
		atributeTypes[traitKey] = traitType;
		traitChances[traitKey] = traitChance - 1; //0 will represent 1% and 99 100%
		traitKeysByName[traitLabel] = traitKey;
		traitKeysByIndex[traitsLength] = traitKey;
		traitKeyIndex[keccak256(abi.encodePacked(traitLabel))] = traitsLength;
		_;
		traitsLength++;
	}

	function getTraitNumberConfig(uint8 traitKeyId) external view returns (uint32 min, uint32 max) {
		return (traitNumberMin[traitKeyId], traitNumberMax[traitKeyId]);
	}

	function getTraitOptionsLabel(uint8 traitKeyId, uint32 traitId) external view returns (string memory) {
		return traitOptionLabels[traitKeyId][traitId];
	}

	function getTraitOptionChance(uint8 traitKeyId, uint32 traitId) external view returns (uint8) {
		return traitOptionChances[traitKeyId][traitId];
	}

	function getTraitOptionsImage(uint8 traitKeyId, uint32 traitId) external view returns (string memory result) {
		if (traitOptionImages[traitKeyId].length == 0) {
			result = "";
		} else {
			result = traitOptionImages[traitKeyId][traitId];
		}
	}

	function getNumberOfTraits() external view returns (uint8 numberOfTraits) {
		return traitsLength;
	}

	function getTraitOptionChances(uint8 traitKeyId) external view returns (uint8[] memory) {
		return traitOptionChances[traitKeyId];
	}

	function getTraitLabel(uint8 traitKeyId) external view returns (string memory) {
		return traitLabels[traitKeyId];
	}

	function getTraitKeyType(uint8 traitKeyId) external view returns (Types.TraitType) {
		return atributeTypes[traitKeyId];
	}

	function getTraitChance(uint8 traitKeyId) external view returns (uint8) {
		return traitChances[traitKeyId];
	}

	function getTraitKeyByIndex(uint8 traitIndex) external view returns (uint8) {
		return traitKeysByIndex[traitIndex];
	}

	function generateNFT(uint genes) external view returns (Types.NFT memory) {
		return Generator.generateNFT(this, genes);
	}

	function getTraitKeyByName(string memory traitName) external view returns (uint8) {
		return traitKeysByName[traitName];
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

	function getTraitIndexByKey(bytes32 traitKey) external view override returns (uint8) {
		return traitKeyIndex[traitKey];
	}
}
