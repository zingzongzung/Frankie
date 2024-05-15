// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./CollectionConfigBase.sol";
import "../../libraries/Constants.sol";

contract PassConfig is CollectionConfigBase {
	constructor() {
		randomTraits = false;
		addTextTrait(Constants.PASS_COLLECTION_LABEL, 100, bytes32(0));
		addTextTrait(Constants.PASS_COLLECTION_ADDRESS_LABEL, 100, bytes32(0));
	}

	function getKnownFields() public pure returns (bytes32 collectionLabel, bytes32 collectionAddressLabel) {
		return (Constants.PASS_COLLECTION_LABEL, Constants.PASS_COLLECTION_ADDRESS_LABEL);
	}
}
