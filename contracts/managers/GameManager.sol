// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./NFTManager.sol";
import "../libraries/Generator.sol";

contract GameManager is NFTManager {
	function rerollAttribute(
		address nftCollectionAddress,
		uint256 tokenId,
		uint8 traitKey
	) external view onlyAuthorizedCollections(nftCollectionAddress) returns (Types.Trait memory result) {
		ICollectionGenerator generator = ICollectionGenerator(nftCollectionAddress);
		ICollection collection = ICollection(generator.getCollectionAddress());

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

				break;
			}
		}

		return result;
	}
}
