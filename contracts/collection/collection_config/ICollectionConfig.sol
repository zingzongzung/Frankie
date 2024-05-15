// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../libraries/Types.sol";

interface ICollectionConfig {
	function setCollectionAttributes(uint256 _collectionPrice, uint16 _svgBoxHeight, uint16 _svgBoxWidth) external;

	function getCollectionAttributes() external view returns (uint256 _collectionPrice, uint16 _svgBoxHeight, uint16 _svgBoxWidth);

	//Collection Creation
	function addOptionsTrait(bytes32 traitKey, uint8 traitChance, bytes32[] memory valueLabels, uint8[] memory chances) external;

	function addOptionsWithImageTrait(bytes32 traitKey, uint8 traitChance, bytes32[] memory valueLabels, uint8[] memory chances, string[] memory images) external;

	function addNumberTrait(bytes32 traitKey, uint8 traitChance, uint8 min, uint8 max) external;

	function addTextTrait(bytes32 traitKey, uint8 traitChance, bytes32 defaultValue) external;

	//Collection Generation
	function getTraitKeyByIndex(uint8 traitIndex) external view returns (bytes32);

	function getTraitType(bytes32 traitKey) external view returns (Types.TraitType);

	function getTraitChance(bytes32 traitKey) external view returns (uint8);

	function getTraitNumberConfig(bytes32 traitKey) external view returns (uint32, uint32);

	function getTraitOptionChances(bytes32 traitKey) external view returns (uint8[] memory);

	function hasRandomTraits() external view returns (bool);

	//Collection querying
	function getNumberOfTraits() external view returns (uint8);

	function getTraitTextValue(bytes32 traitKey) external view returns (bytes32);

	function getTraitOptionsImage(bytes32 traitKey, bytes32 traitValue) external view returns (string memory);

	function getTraitOptionsLabel(bytes32 traitKey, uint32 traitId) external view returns (bytes32);

	function generateNFT(uint genes) external view returns (Types.Trait[] memory);
}
