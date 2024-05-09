// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../collection/collection_config/ICollectionConfig.sol";
import "./NumberUtils.sol";
import "./Types.sol";

library Generator {
	function generateNFT(ICollectionConfig myCollection, uint genes) internal view returns (Types.Trait[] memory result) {
		//78 is the maximum length for the genes, when current position reaches 78, restart
		uint8 genesIndex = 0;
		Types.TraitType currentTraitType;
		uint8 numberOfTraits = myCollection.getNumberOfTraits();
		bool hasTrait;

		uint8 genesLength = NumberUtils.countDigits(genes);
		bytes32 traitKey;

		result = new Types.Trait[](numberOfTraits);

		for (uint8 i; i < numberOfTraits; i++) {
			traitKey = myCollection.getTraitKeyByIndex(i);
			(hasTrait, genesIndex) = performTraitChanceCheck(genes, genesIndex, myCollection.getTraitChance(traitKey), genesLength);

			if (hasTrait) {
				currentTraitType = myCollection.getTraitType(traitKey);
				Types.Trait memory generatedTrait;
				if (currentTraitType == Types.TraitType.Number) {
					(genesIndex, generatedTrait) = generateNumberTrait(myCollection, genes, genesLength, genesIndex, traitKey);
				} else if (currentTraitType == Types.TraitType.Options || currentTraitType == Types.TraitType.OptionsWithImage) {
					(genesIndex, generatedTrait) = generateOptionsTrait(myCollection, genes, genesLength, genesIndex, traitKey, currentTraitType);
				} else if (currentTraitType == Types.TraitType.Text) {
					generatedTrait = generateTextTrait(myCollection, traitKey);
				}
				result[i] = generatedTrait;
			}
		}

		return result;
	}

	function generateNumberTrait(
		ICollectionConfig myCollection,
		uint genes,
		uint8 genesLength,
		uint8 genesIndex,
		bytes32 traitKey
	) internal view returns (uint8, Types.Trait memory) {
		uint32 traitValue;
		uint32 traitNumberGenes;

		(uint32 traitMin, uint32 traitMax) = myCollection.getTraitNumberConfig(traitKey);
		(traitNumberGenes, genesIndex) = NumberUtils.extractDigits(genes, genesIndex, NumberUtils.countDigits(traitMax), genesLength);

		traitValue = NumberUtils.mapToRange(traitMin, traitMax, traitNumberGenes);
		Types.Trait memory trait = rollNumberTrait(myCollection, traitNumberGenes, traitKey);

		return (genesIndex, trait);
	}

	function generateTextTrait(ICollectionConfig myCollection, bytes32 traitKey) internal view returns (Types.Trait memory generatedTrait) {
		generatedTrait = Types.Trait(true, Types.TraitType.Text, traitKey, myCollection.getTraitTextValue(traitKey));

		return generatedTrait;
	}

	function generateOptionsTrait(
		ICollectionConfig myCollection,
		uint genes,
		uint8 genesLength,
		uint8 genesIndex,
		bytes32 attrKey,
		Types.TraitType traitType
	) internal view returns (uint8, Types.Trait memory) {
		uint32 chancesGene;
		(chancesGene, genesIndex) = getChancesGene(genes, genesIndex, genesLength);

		Types.Trait memory trait = rollOptionsTrait(myCollection, chancesGene, attrKey, traitType);

		return (genesIndex, trait);
	}

	function rollNumberTrait(ICollectionConfig myCollection, uint32 traitNumberGenes, bytes32 traitKey) internal view returns (Types.Trait memory) {
		uint32 traitValue;

		(uint32 traitMin, uint32 traitMax) = myCollection.getTraitNumberConfig(traitKey);

		traitValue = NumberUtils.mapToRange(traitMin, traitMax, traitNumberGenes);
		return Types.Trait(true, Types.TraitType.Number, traitKey, bytes32(uint256(traitValue)));
	}

	function rollOptionsTrait(ICollectionConfig myCollection, uint32 chancesGene, bytes32 attrKey, Types.TraitType traitType) internal view returns (Types.Trait memory result) {
		uint32 currentChance = 0;

		uint8[] memory traitChances = myCollection.getTraitOptionChances(attrKey);
		uint256 traitsLength = traitChances.length;
		for (uint8 traitIndex; traitIndex < traitsLength; traitIndex++) {
			currentChance = currentChance + traitChances[traitIndex];
			if (performChanceCheck(currentChance, chancesGene)) {
				result = Types.Trait(true, traitType, attrKey, myCollection.getTraitOptionsLabel(attrKey, traitIndex));
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
