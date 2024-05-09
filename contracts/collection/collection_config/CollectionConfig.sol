// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./CollectionConfigBase.sol";
import "../../libraries/Generator.sol";
import "../../managers/nfts/PassManager.sol";

contract CollectionConfig is CollectionConfigBase {
	//Pass Manager
	Types.Pass pass;
	PassManager passManager;

	constructor(address passManagerAddress, address passAddress, uint passId, bytes32 hashedMessage, bytes memory signature, bytes32 _collectionName) {
		passManager = PassManager(passManagerAddress);
		passManager.isAuthorized(passAddress, passId, hashedMessage, signature);
		// passManager.isAuthorizedV2(passAddress, passId, _collectionName, signature);
		isCollectionClosed = false;
		collectionName = _collectionName;
		pass = Types.Pass(passAddress, passId);
		passManager.setPassUsed(passAddress, passId, _collectionName);
	}
}
