// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./CollectionConfigBase.sol";
import "../../libraries/Constants.sol";

contract PassConfig is CollectionConfigBase {
	constructor() {
		randomTraits = false;
		addTextTrait(Constants.PASS_COLLECTION_LABEL, 100, bytes32(0));
		addTextTrait(Constants.PASS_COLLECTION_ADDRESS_LABEL, 100, bytes32(0));

		bytes32[] memory valueLabels = new bytes32[](1);
		valueLabels[0] = Constants.PASS_IMAGE_VALUE;

		uint8[] memory chances = new uint8[](1);
		chances[0] = 100;

		string[] memory images = new string[](1);
		images[0] = Constants.PASS_IMAGE_HASH;

		addOptionsWithImageTrait(Constants.PASS_IMAGE_KEY, 100, valueLabels, chances, images);
	}

	function getPassTraits() public pure returns (bytes32 collectionLabel, bytes32 collectionAddressLabel, bytes32 imageLabel) {
		return (Constants.PASS_COLLECTION_LABEL, Constants.PASS_COLLECTION_ADDRESS_LABEL, Constants.PASS_IMAGE_KEY);
	}

	function getPassSettings() external pure override returns (bool, Types.Pass memory pass, PassManager passManager) {
		return (true, pass, passManager);
	}
}
