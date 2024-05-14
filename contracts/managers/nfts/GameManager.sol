// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./NFTManagerBase.sol";
import "../../libraries/Generator.sol";
import "../../libraries/Roles.sol";

contract GameManager is NFTManagerBase {
	uint256[] requests;
	uint256[] processedRequests;

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
		collection.setTrait(tokenId, result);
	}

	function getProcessedRequests() external view returns (uint256[] memory, uint256[] memory) {
		return (requests, processedRequests);
	}
}
