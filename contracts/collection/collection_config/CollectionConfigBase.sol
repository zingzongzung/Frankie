// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ICollectionConfig.sol";
import "../../libraries/Generator.sol";
import "../../managers/nfts/PassManager.sol";

abstract contract CollectionConfigBase is ICollectionConfig {
	//Collection attributes
	bytes32 collectionName;
	uint256 collectionPrice;
	uint16 svgBoxHeight;
	uint16 svgBoxWidth;

	//This represents all the collectionTraits that can be part of an NFT
	uint8 traitsLength;
	mapping(bytes32 => Types.TraitType) traitTypes;
	mapping(bytes32 => uint8) traitChances; //Percentage between 0 and 99

	//Array Types
	mapping(bytes32 => bytes32[]) traitOptionLabels;
	mapping(bytes32 => uint8[]) traitOptionChances;
	//mapping(bytes32 => string[]) traitOptionImages;
	mapping(bytes32 => mapping(bytes32 => string)) traitOptionImages;

	//Number Types
	mapping(bytes32 => uint32) traitNumberMin;
	mapping(bytes32 => uint32) traitNumberMax;

	//Text Types
	mapping(bytes32 => bytes32) traitDefaultValue;

	//Indexing
	mapping(uint8 => bytes32) traitKeysByIndex;

	bool isCollectionClosed;
	bool randomTraits;

	function setCollectionAttributes(uint256 _collectionPrice, uint16 _svgBoxHeight, uint16 _svgBoxWidth) external {
		collectionPrice = _collectionPrice;
		svgBoxHeight = _svgBoxHeight;
		svgBoxWidth = _svgBoxWidth;
	}

	function getCollectionAttributes() external view override returns (uint256 _collectionPrice, uint16 _svgBoxHeight, uint16 _svgBoxWidth) {
		_collectionPrice = collectionPrice;
		_svgBoxHeight = svgBoxHeight;
		_svgBoxWidth = svgBoxWidth;
	}

	modifier addBaseTrait(
		bytes32 traitKey,
		Types.TraitType traitType,
		uint8 traitChance
	) {
		require(traitChance > 0 && traitChance <= 100, "Chance must be a positive number less than 100");
		traitTypes[traitKey] = traitType;
		traitChances[traitKey] = traitChance - 1; //0 will represent 1% and 99 100%
		traitKeysByIndex[traitsLength] = traitKey;
		_;
		traitsLength++;
	}

	function addOptionsTrait(
		bytes32 traitKey,
		uint8 traitChance,
		bytes32[] memory valueLabels,
		uint8[] memory chances
	) public override addBaseTrait(traitKey, Types.TraitType.Options, traitChance) {
		require(chances.length == valueLabels.length, "Invalid arrays");
		require(NumberUtils.sum(chances) == 100);
		traitOptionChances[traitKey] = chances;
		traitOptionLabels[traitKey] = valueLabels;
	}

	function addOptionsWithImageTrait(
		bytes32 traitKey,
		uint8 traitChance,
		bytes32[] memory valueLabels,
		uint8[] memory chances,
		string[] memory images
	) public override addBaseTrait(traitKey, Types.TraitType.OptionsWithImage, traitChance) {
		require(chances.length == valueLabels.length, "Invalid arrays");
		require(NumberUtils.sum(chances) == 100);
		for (uint256 currentIndex; currentIndex < valueLabels.length; currentIndex++) {
			traitOptionImages[traitKey][valueLabels[currentIndex]] = images[currentIndex];
		}

		traitOptionChances[traitKey] = chances;
		traitOptionLabels[traitKey] = valueLabels;
	}

	function addNumberTrait(bytes32 traitKey, uint8 traitChance, uint8 min, uint8 max) public override addBaseTrait(traitKey, Types.TraitType.Number, traitChance) {
		require(min <= max, "Min should be less than max");
		traitNumberMin[traitKey] = min;
		traitNumberMax[traitKey] = max;
	}

	function addTextTrait(bytes32 traitKey, uint8 traitChance, bytes32 defaultValue) public override addBaseTrait(traitKey, Types.TraitType.Text, traitChance) {
		traitDefaultValue[traitKey] = defaultValue;
	}

	function getTraitKeyByIndex(uint8 traitIndex) external view returns (bytes32) {
		return traitKeysByIndex[traitIndex];
	}

	function getTraitType(bytes32 traitKey) external view returns (Types.TraitType) {
		return traitTypes[traitKey];
	}

	function getTraitChance(bytes32 traitKey) external view override returns (uint8) {
		return traitChances[traitKey];
	}

	function getTraitNumberConfig(bytes32 traitKey) external view override returns (uint32, uint32) {
		return (traitNumberMin[traitKey], traitNumberMax[traitKey]);
	}

	function getTraitOptionChances(bytes32 traitKey) external view override returns (uint8[] memory) {
		return traitOptionChances[traitKey];
	}

	function getTraitOptionsImage(bytes32 traitKey, bytes32 traitValue) external view override returns (string memory) {
		return traitOptionImages[traitKey][traitValue];
	}

	function getTraitOptionsLabel(bytes32 traitKey, uint32 traitId) external view override returns (bytes32) {
		return traitOptionLabels[traitKey][traitId];
	}

	function getNumberOfTraits() external view override returns (uint8) {
		return traitsLength;
	}

	function getTraitTextValue(bytes32 traitKey) external view override returns (bytes32) {
		return traitDefaultValue[traitKey];
	}

	function generateNFT(uint genes) external view override returns (Types.Trait[] memory) {
		return Generator.generateNFT(this, genes);
	}

	function hasRandomTraits() external view returns (bool) {
		return randomTraits;
	}
}
