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
		uint8 traitKey
	) external onlyAuthorizedCollections(nftCollectionAddress) returns (Types.Trait memory result) {
		(ICollectionConfig collection, ICollectionNFT generator) = getCollection(nftCollectionAddress);
		require(generator.getOwner(tokenId) == msg.sender, "This nft is not owned by the sender!");

		Types.NFT memory nft = generator.getNFTDetails(tokenId);
		Types.TraitType traitType = collection.getTraitKeyType(traitKey);

		uint8 numberOfTraits = collection.getNumberOfTraits();
		for (uint8 index; index < numberOfTraits; index++) {
			if (nft.traits[index].key == traitKey) {
				if (traitType == Types.TraitType.Number) {
					result = Generator.rollNumberTrait(collection, 99, traitKey);
				}
				if (traitType == Types.TraitType.Options || traitType == Types.TraitType.OptionsWithImage) {
					result = Generator.rollOptionsTrait(collection, 99, traitKey, traitType);
				}
				generator.setTrait(tokenId, index, result);
				break;
			}
		}
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
