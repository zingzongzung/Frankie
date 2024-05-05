// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../nfts/interfaces/ICollectionConfig.sol";
import "./NumberUtils.sol";
import "./Types.sol";

library Generator {
	function generateNFT(ICollectionConfig myCollection, uint genes) internal view returns (Types.NFT memory) {
		//78 is the maximum length for the genes, when current position reaches 78, restart
		uint8 genesIndex = 0;
		Types.TraitType currentTraitType;
		uint8 numberOfTraits = myCollection.getNumberOfTraits();
		bool hasTrait;

		Types.NFT memory result;
		result.traits = new Types.Trait[](numberOfTraits);
		result.chancesGene = new uint32[](numberOfTraits);

		result.genes = genes;
		result.genesLength = NumberUtils.countDigits(genes);

		uint8 traitKey;

		for (uint8 i; i < numberOfTraits; i++) {
			traitKey = myCollection.getTraitKeyByIndex(i);
			(uint32 chancesGene, ) = getChancesGene(genes, genesIndex, result.genesLength);
			(hasTrait, genesIndex) = performTraitChanceCheck(genes, genesIndex, myCollection.getTraitChance(traitKey), result.genesLength);

			result.chancesGene[i] = chancesGene;
			if (hasTrait) {
				currentTraitType = myCollection.getTraitKeyType(traitKey);
				if (currentTraitType == Types.TraitType.Number) {
					genesIndex = generateNumberTrait(myCollection, genesIndex, traitKey, result, i);
				} else if (currentTraitType == Types.TraitType.Options || currentTraitType == Types.TraitType.OptionsWithImage) {
					genesIndex = generateOptionsTrait(myCollection, genesIndex, traitKey, result, i, currentTraitType);
				}
			}
		}

		return result;
	}

	function generateNumberTrait(ICollectionConfig myCollection, uint8 genesIndex, uint8 traitKey, Types.NFT memory myNft, uint8 nftTraitIndex) internal view returns (uint8) {
		uint32 traitValue;
		uint32 traitNumberGenes;

		(uint32 traitMin, uint32 traitMax) = myCollection.getTraitNumberConfig(traitKey);
		(traitNumberGenes, genesIndex) = NumberUtils.extractDigits(myNft.genes, genesIndex, NumberUtils.countDigits(traitMax), myNft.genesLength);

		traitValue = NumberUtils.mapToRange(traitMin, traitMax, traitNumberGenes);
		myNft.traits[nftTraitIndex] = rollNumberTrait(myCollection, traitNumberGenes, traitKey);

		return genesIndex;
	}

	function generateOptionsTrait(
		ICollectionConfig myCollection,
		uint8 genesIndex,
		uint8 attrKey,
		Types.NFT memory myNft,
		uint8 nftTraitIndex,
		Types.TraitType traitType
	) internal view returns (uint8) {
		uint32 chancesGene;
		(chancesGene, genesIndex) = getChancesGene(myNft.genes, genesIndex, myNft.genesLength);

		myNft.traits[nftTraitIndex] = rollOptionsTrait(myCollection, chancesGene, attrKey, traitType);

		return genesIndex;
	}

	function rollNumberTrait(ICollectionConfig myCollection, uint32 traitNumberGenes, uint8 traitKey) internal view returns (Types.Trait memory) {
		uint32 traitValue;

		(uint32 traitMin, uint32 traitMax) = myCollection.getTraitNumberConfig(traitKey);

		traitValue = NumberUtils.mapToRange(traitMin, traitMax, traitNumberGenes);
		return Types.Trait(Types.TraitType.Number, traitKey, true, traitValue);
	}

	function rollOptionsTrait(ICollectionConfig myCollection, uint32 chancesGene, uint8 attrKey, Types.TraitType traitType) internal view returns (Types.Trait memory result) {
		uint32 currentChance = 0;

		uint8[] memory traitChances = myCollection.getTraitOptionChances(attrKey);
		uint256 traitsLength = traitChances.length;
		for (uint8 traitIndex; traitIndex < traitsLength; traitIndex++) {
			currentChance = currentChance + myCollection.getTraitOptionChance(attrKey, traitIndex);
			if (performChanceCheck(currentChance, chancesGene)) {
				result = Types.Trait(traitType, attrKey, true, traitIndex);
				break;
			}
		}

		return result;
	}

	function performChanceCheck(uint32 traitChance, uint32 chancesGene) internal pure returns (bool) {
		return chancesGene <= traitChance;
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
