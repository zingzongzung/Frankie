// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/Collection.sol";

abstract contract NFTGenerator {
	Collection myCollection;

	struct NFT {
		string name;
		uint genes;
		uint8 genesLength;
		Trait[] traits;
	}

	struct Trait {
		Collection.TraitType traitType;
		uint8 key;
		uint32 value;
	}

	mapping(uint => NFT) nfts;
	uint public _nextTokenId;

	function setCollectionAddress(address collectionAddress) internal {
		myCollection = Collection(collectionAddress);
	}

	function generate(string memory name, uint tokenId, uint genes) internal {
		NFT storage myNft = nfts[tokenId];

		//78 is the maximum length for the genes, when current position reaches 78, restart
		uint8 genesIndex = 0;

		Collection.TraitType currentGeneType;
		bool hasTrait;

		myNft.name = name;
		myNft.genes = genes;
		myNft.genesLength = countDigits(genes);

		uint8 numberOfTraits = myCollection.getNumberOfTraits();

		for (uint8 i; i < numberOfTraits; i++) {
			(hasTrait, genesIndex) = performTraitChanceCheck(genes, genesIndex, myCollection.getTraitChance(i), myNft.genesLength);
			if (hasTrait) {
				currentGeneType = myCollection.getTraitKeyType(i);
				if (currentGeneType == Collection.TraitType.Number) {
					genesIndex = generateNumberTrait(genesIndex, i, myNft);
				} else if (currentGeneType == Collection.TraitType.Options) {
					genesIndex = generateOptionsTrat(genesIndex, i, myNft);
				}
			}
		}
	}

	function generateNumberTrait(uint8 currentPosition, uint8 traitKey, NFT storage myNft) internal returns (uint8) {
		uint32 traitValue;
		uint32 traitNumberGenes;

		(uint32 traitMin, uint32 traitMax) = myCollection.getTraitNumberConfig(traitKey);
		(traitNumberGenes, currentPosition) = extractDigits(myNft.genes, currentPosition, countDigits(traitMax), myNft.genesLength);

		traitValue = mapToRange(traitMin, traitMax, traitNumberGenes);
		myNft.traits.push(Trait(Collection.TraitType.Number, traitKey, traitValue));

		return currentPosition;
	}

	function generateOptionsTrat(uint8 genesIndex, uint8 attrKey, NFT storage myNft) internal returns (uint8) {
		uint32 chancesGene;
		(chancesGene, genesIndex) = getChancesGene(myNft.genes, genesIndex, myNft.genesLength);

		uint32 currentChance = 0;

		uint8[] memory traitChances = myCollection.getTraitOptionChances(attrKey);
		uint256 traitsLength = traitChances.length;
		for (uint8 traitIndex; traitIndex < traitsLength; traitIndex++) {
			currentChance = currentChance + myCollection.getTraitOptionChance(attrKey, traitIndex);
			if (performChanceCheck(currentChance, chancesGene)) {
				myNft.traits.push(Trait(Collection.TraitType.Options, attrKey, traitIndex));
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
		(chance, newGenesIndex) = extractDigits(genes, genesIndex, 2, genesLength);
	}

	function getTraitLabel(uint8 traitKey) external view returns (string memory) {
		return myCollection.getTraitLabel(traitKey);
	}

	function getTraitOptionsLabel(uint8 traitKey, uint8 traitValue) external view returns (string memory) {
		return myCollection.getTraitOptionLabel(traitKey, traitValue);
	}

	//Utils
	function getGenomeForDigit(uint8 geneValue, uint8 possibilities) internal pure returns (uint8) {
		return geneValue % possibilities;
	}

	function getNextGenePosition(uint8 currentPosition, uint8 treshold, uint8 digitCount) internal pure returns (uint8 genePosition) {
		if (currentPosition >= treshold) {
			genePosition = 0;
		} else {
			genePosition = currentPosition + digitCount;
		}
	}

	function extractDigits(uint number, uint8 position, uint8 digitCount, uint8 treshold) internal pure returns (uint32, uint8) {
		require(digitCount > 0, "Digit count must be greater than zero");

		// Calculate divisor to isolate desired digits
		uint divisor = 10 ** (position + digitCount);

		// Divide the number to isolate the desired digits
		uint32 extractedNumber = uint32((number % divisor) / (10 ** position));

		return (extractedNumber, getNextGenePosition(position, treshold, digitCount));
	}

	function countDigits(uint value) public pure returns (uint8) {
		// Special case for the value zero
		if (value == 0) {
			return 1;
		}

		uint8 count = 0;
		while (value != 0) {
			count += 1;
			value /= 10;
		}

		return count;
	}

	function mapToRange(uint32 min, uint32 max, uint32 randomNumber) public pure returns (uint32) {
		require(min < max, "Min must be less than max");

		// Calculate the range size
		uint32 rangeSize = max - min + 1;

		// Map randomNumber to the range size and add min to shift to the correct range
		uint32 mappedNumber = (randomNumber % rangeSize) + min;

		return mappedNumber;
	}

	/**
	 *
	 * Used to get the number to multiply by the origin digit to create origin genes composed
	 *
	 * @param numDigits number of digits
	 */
	function closestPowerOfTen(uint numDigits) public pure returns (uint) {
		if (numDigits <= 1) {
			return 1; // The closest power of ten to numbers with 1 or 0 digits is 1
		}

		uint power = 1;
		for (uint i = 1; i < numDigits; i++) {
			power *= 10;
		}
		return power;
	}
}
