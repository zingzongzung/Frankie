// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/Collection.sol";
import "./NFTRandomManager.sol";
import "./libraries/NumberUtils.sol";

abstract contract NFTGenerator {
	Collection myCollection;

	NFTRandomManager nftRandomManager;

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

	function init(address collectionAddress, address nftRandomManagerAddress) internal {
		myCollection = Collection(collectionAddress);
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	function getNFTDetails(uint256 tokenId) public view returns (NFT memory) {
		return nfts[tokenId];
	}

	function startRandomProcess(uint256 tokenId, string memory name) internal {
		NFT storage myNft = nfts[tokenId];
		myNft.name = name;
		nftRandomManager.requestRandomWords(address(this), tokenId);
	}

	function generate(uint tokenId, uint genes) external {
		_generate("", tokenId, genes);
	}

	function _generate(string memory name, uint tokenId, uint genes) internal {
		NFT storage myNft = nfts[tokenId];

		//78 is the maximum length for the genes, when current position reaches 78, restart
		uint8 genesIndex = 0;

		Collection.TraitType currentGeneType;
		bool hasTrait;

		if (bytes(name).length == 0) {
			myNft.name = name;
		}

		myNft.genes = genes;
		myNft.genesLength = NumberUtils.countDigits(genes);

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
		(traitNumberGenes, currentPosition) = NumberUtils.extractDigits(myNft.genes, currentPosition, NumberUtils.countDigits(traitMax), myNft.genesLength);

		traitValue = NumberUtils.mapToRange(traitMin, traitMax, traitNumberGenes);
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
		(chance, newGenesIndex) = NumberUtils.extractDigits(genes, genesIndex, 2, genesLength);
	}

	function getTraitLabel(uint8 traitKey) external view returns (string memory) {
		return myCollection.getTraitLabel(traitKey);
	}

	function getTraitOptionsLabel(uint8 traitKey, uint8 traitValue) external view returns (string memory) {
		return myCollection.getTraitOptionLabel(traitKey, traitValue);
	}
}
