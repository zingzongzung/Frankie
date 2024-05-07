// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../libraries/Types.sol";

interface ICollectionConfig {
	function setCollectionAttributes(uint256 _collectionPrice, uint16 _svgBoxHeight, uint16 _svgBoxWidth) external;

	function getCollectionAttributes() external view returns (uint256 _collectionPrice, uint16 _svgBoxHeight, uint16 _svgBoxWidth);

	function addOptionsTrait(uint8 traitKey, string memory traitLabel, uint8 traitChance, string[] memory valueLabels, uint8[] memory chances) external;

	function addOptionsWithImageTrait(
		uint8 traitKey,
		string memory traitLabel,
		uint8 traitChance,
		string[] memory valueLabels,
		uint8[] memory chances,
		string[] memory images
	) external;

	function addNumberTrait(uint8 traitKey, string memory traitLabel, uint8 traitChance, uint8 min, uint8 max) external;

	function getTraitNumberConfig(uint8 traitKeyId) external view returns (uint32 min, uint32 max);

	function getTraitOptionsLabel(uint8 traitKeyId, uint32 traitId) external view returns (string memory);

	function getTraitOptionChance(uint8 traitKeyId, uint32 traitId) external view returns (uint8);

	function getTraitOptionsImage(uint8 traitKeyId, uint32 traitId) external view returns (string memory result);

	function getNumberOfTraits() external view returns (uint8 numberOfTraits);

	function getTraitOptionChances(uint8 traitKeyId) external view returns (uint8[] memory);

	function getTraitLabel(uint8 traitKeyId) external view returns (string memory);

	function getTraitKeyType(uint8 traitKeyId) external view returns (Types.TraitType);

	function getTraitChance(uint8 traitKeyId) external view returns (uint8);

	function getTraitKeyByIndex(uint8 traitIndex) external view returns (uint8);

	function generateNFT(uint genes) external view returns (Types.NFT memory);

	function getTraitKeyByName(string memory traitName) external view returns (uint8);

	//IERC7496
	function getTraitIndexByKey(bytes32 traitKey) external view returns (uint8);
}
