// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../interfaces/Collection.sol";
import "./NumberUtils.sol";

library Generator {
	struct NFT {
		string name;
		uint genes;
		uint8 genesLength;
		Trait[] traits;
	}

	struct Trait {
		Collection.TraitType traitType;
		uint8 key;
		bool isDefined;
		uint32 value;
	}

	function generateNFT(Collection myCollection, uint genes) internal view returns (NFT memory) {
		//78 is the maximum length for the genes, when current position reaches 78, restart
		uint8 genesIndex = 0;
		Collection.TraitType currentTraitType;
		uint8 numberOfTraits = myCollection.getNumberOfTraits();
		bool hasTrait;

		NFT memory result;
		result.traits = new Trait[](numberOfTraits);

		result.genes = genes;
		result.genesLength = NumberUtils.countDigits(genes);

		uint8 traitKey;

		for (uint8 i; i < numberOfTraits; i++) {
			traitKey = myCollection.getTraitKeyByIndex(i);
			(hasTrait, genesIndex) = performTraitChanceCheck(genes, genesIndex, myCollection.getTraitChance(traitKey), result.genesLength);
			if (hasTrait) {
				currentTraitType = myCollection.getTraitKeyType(traitKey);
				if (currentTraitType == Collection.TraitType.Number) {
					genesIndex = generateNumberTrait(myCollection, genesIndex, traitKey, result, i);
				} else if (currentTraitType == Collection.TraitType.Options) {
					genesIndex = generateOptionsTrait(myCollection, genesIndex, traitKey, result, i);
				}
			}
		}

		return result;
	}

	function generateNumberTrait(Collection myCollection, uint8 genesIndex, uint8 traitKey, NFT memory myNft, uint8 nftTraitIndex) internal view returns (uint8) {
		uint32 traitValue;
		uint32 traitNumberGenes;

		(uint32 traitMin, uint32 traitMax) = myCollection.getTraitNumberConfig(traitKey);
		(traitNumberGenes, genesIndex) = NumberUtils.extractDigits(myNft.genes, genesIndex, NumberUtils.countDigits(traitMax), myNft.genesLength);

		traitValue = NumberUtils.mapToRange(traitMin, traitMax, traitNumberGenes);
		myNft.traits[nftTraitIndex] = Trait(Collection.TraitType.Number, traitKey, true, traitValue);

		return genesIndex;
	}

	function generateOptionsTrait(Collection myCollection, uint8 genesIndex, uint8 attrKey, NFT memory myNft, uint8 nftTraitIndex) internal view returns (uint8) {
		uint32 chancesGene;
		(chancesGene, genesIndex) = getChancesGene(myNft.genes, genesIndex, myNft.genesLength);

		uint32 currentChance = 0;

		uint8[] memory traitChances = myCollection.getTraitOptionChances(attrKey);
		uint256 traitsLength = traitChances.length;
		for (uint8 traitIndex; traitIndex < traitsLength; traitIndex++) {
			currentChance = currentChance + myCollection.getTraitOptionChance(attrKey, traitIndex);
			if (performChanceCheck(currentChance, chancesGene)) {
				myNft.traits[nftTraitIndex] = Trait(Collection.TraitType.Options, attrKey, true, traitIndex);
				break;
			}
		}

		return genesIndex;
	}

	function performChanceCheck(uint32 traitChance, uint32 chancesGene) internal pure returns (bool) {
		return chancesGene < traitChance;
	}

	function performTraitChanceCheck(uint256 genes, uint8 genesIndex, uint32 traitChance, uint8 genesLength) internal pure returns (bool hasTrait, uint8 newGenesIndex) {
		uint32 chancesGene;
		(chancesGene, newGenesIndex) = getChancesGene(genes, genesIndex, genesLength);
		hasTrait = performChanceCheck(traitChance, chancesGene);
	}

	function getChancesGene(uint256 genes, uint8 genesIndex, uint8 genesLength) internal pure returns (uint32 chance, uint8 newGenesIndex) {
		(chance, newGenesIndex) = NumberUtils.extractDigits(genes, genesIndex, 2, genesLength);
	}
}
