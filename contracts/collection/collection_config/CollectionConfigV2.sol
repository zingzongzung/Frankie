// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ICollectionConfigV2.sol";
import "../../libraries/GeneratorV2.sol";
import "../../managers/nfts/PassManager.sol";

contract CollectionConfigV2 is ICollectionConfigV2 {
	//Pass Manager
	Types.Pass pass;
	PassManager passManager;

	//Collection attributes
	uint256 private collectionPrice;
	uint16 private svgBoxHeight;
	uint16 private svgBoxWidth;

	//This represents all the collectionTraits that can be part of an NFT
	uint8 traitsLength;
	mapping(bytes32 => Types.TraitType) traitTypes;
	mapping(bytes32 => uint8) traitChances; //Percentage between 0 and 99

	//Array Types
	mapping(bytes32 => bytes32[]) traitOptionLabels;
	mapping(bytes32 => uint8[]) traitOptionChances;
	mapping(bytes32 => string[]) traitOptionImages;

	//Number Types
	mapping(bytes32 => uint32) traitNumberMin;
	mapping(bytes32 => uint32) traitNumberMax;

	//Text Types
	mapping(bytes32 => bytes32) traitDefaultValue;

	//Indexing
	mapping(uint8 => bytes32) traitKeysByIndex;

	bool isCollectionClosed;

	constructor(address passManagerAddress, address passAddress, uint passId, bytes32 originalMessage, bytes memory signature) {
		passManager = PassManager(passManagerAddress);
		//passManager.isAuthorizedV2(passAddress, passId, originalMessage, signature);
		passManager.isAuthorized(passAddress, passId, originalMessage, signature);
		isCollectionClosed = false;
		pass = Types.Pass(passAddress, passId);
		passManager.setPassUsed(passAddress, passId);
	}

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
		traitOptionImages[traitKey] = images;
		traitOptionChances[traitKey] = chances;
		traitOptionLabels[traitKey] = valueLabels;
	}

	function addNumberTrait(bytes32 traitKey, uint8 traitChance, uint8 min, uint8 max) external override addBaseTrait(traitKey, Types.TraitType.Number, traitChance) {
		require(min <= max, "Min should be less than max");
		traitNumberMin[traitKey] = min;
		traitNumberMax[traitKey] = max;
	}

	function addTextTrait(bytes32 traitKey, uint8 traitChance, bytes32 defaultValue) external override addBaseTrait(traitKey, Types.TraitType.Text, traitChance) {
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

	function getTraitOptionsImage(bytes32 traitKey, uint32 traitId) external view override returns (string memory) {
		return traitOptionImages[traitKey][traitId];
	}

	function getTraitOptionsLabel(bytes32 traitKey, uint32 traitId) external view override returns (bytes32) {
		return traitOptionLabels[traitKey][traitId];
	}

	function getNumberOfTraits() external view override returns (uint8) {
		return traitsLength;
	}

	//IMPLENMENT
	function getTraitValue(bytes32 traitKey) external view override returns (bytes32) {
		Types.TraitType traitType = traitTypes[traitKey];
		if (traitType == Types.TraitType.Number) {}
	}

	function generateNFT(uint genes) external view override returns (Types.NFTV2 memory) {
		return GeneratorV2.generateNFT(this, genes);
	}
}
