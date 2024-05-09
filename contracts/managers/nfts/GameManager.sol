// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./NFTManagerBase.sol";
import "../../libraries/Generator.sol";
import "../../managers/automation/IAutomationCallback.sol";
import "../../managers/automation/IAutomationManager.sol";
import "../../libraries/Roles.sol";

contract GameManager is NFTManagerBase, IAutomationCallback {
	IAutomationManager private automationManager;

	uint256[] requests;
	uint256[] processedRequests;

	constructor(address automationManagerAddress) NFTManagerBase() {
		updateAutomationManager(automationManagerAddress);
	}

	function updateAutomationManager(address automationManagerAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		automationManager = IAutomationManager(automationManagerAddress);
	}

	function rerollAttribute(
		address nftCollectionAddress,
		uint256 tokenId,
		bytes32 traitKey
	) external onlyAuthorizedCollections(nftCollectionAddress) returns (Types.Trait memory result) {
		ICollectionNFT collection = getCollectionContract(nftCollectionAddress);
		ICollectionConfig collectionConfig = getCollectionConfigContract(collection);
		require(collection.getOwner(tokenId) == msg.sender, "This nft is not owned by the sender!");

		Types.Trait memory trait = collection.getTraitByKey(tokenId, traitKey);
		Types.TraitType traitType = trait.traitType;
		if (traitType == Types.TraitType.Number) {
			result = Generator.rollNumberTrait(collectionConfig, 99, traitKey);
		}
		if (traitType == Types.TraitType.Options || traitType == Types.TraitType.OptionsWithImage) {
			result = Generator.rollOptionsTrait(collectionConfig, 99, traitKey, traitType);
		}
		collection.setTrait(tokenId, traitKey, result);
	}

	function testeRegisterNewAutomation() external {
		automationManager.registerUpkeep(address(this), requests.length);
		requests.push(requests.length);
	}

	function executeAction(uint action) external override onlyRole(Roles.AUTOMATION_MANAGER) {
		processedRequests.push(action);
	}

	function getProcessedRequests() external view returns (uint256[] memory, uint256[] memory) {
		return (requests, processedRequests);
	}
}
