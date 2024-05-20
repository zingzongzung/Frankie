// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./CollectionConfigBase.sol";
import "../../libraries/Generator.sol";
import "../../managers/nfts/PassManager.sol";

contract CollectionConfig is CollectionConfigBase {
	//Pass Manager
	Types.Pass pass;
	PassManager passManager;
	ICollectionNFT passNFT;

	constructor(address payable passManagerAddress, address passAddress, uint passId, bytes memory signature, bytes32 _collectionName) Ownable(msg.sender) {
		randomTraits = true;
		passManager = PassManager(passManagerAddress);
		passManager.isAuthorized(passAddress, passId, _collectionName, signature);
		isCollectionClosed = false;
		collectionName = _collectionName;
		pass = Types.Pass(passAddress, passId);
		passNFT = ICollectionNFT(passAddress);
		passManager.setPassUsed(passAddress, passId, _collectionName);
	}

	function getPassSettings() external view override returns (bool, Types.Pass memory, PassManager) {
		return (false, pass, passManager);
	}

	function setPrice(uint _collectionPrice) external override {
		require(isCollectionOwner(msg.sender), "Not the owner of the pass that has the owneship of this collection");
		collectionPrice = _collectionPrice;
	}

	function isCollectionOwner(address addressToVerify) public view override returns (bool) {
		return addressToVerify == passNFT.getOwner(pass.passId);
	}

	function getCollectionOwner() external view override returns (address) {
		return passNFT.getOwner(pass.passId);
	}
}
