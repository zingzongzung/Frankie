// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./CollectionConfigBase.sol";
import "../../libraries/Generator.sol";
import "../../managers/nfts/PassManager.sol";

contract CollectionConfig is CollectionConfigBase {
	//Pass Manager
	Types.Pass pass;
	PassManager passManager;

	constructor(address passManagerAddress, address passAddress, uint passId, bytes32 originalMessage, bytes memory signature) {
		passManager = PassManager(passManagerAddress);
		//passManager.isAuthorizedV2(passAddress, passId, originalMessage, signature);
		passManager.isAuthorized(passAddress, passId, originalMessage, signature);
		isCollectionClosed = false;
		pass = Types.Pass(passAddress, passId);
		passManager.setPassUsed(passAddress, passId);
	}
}
