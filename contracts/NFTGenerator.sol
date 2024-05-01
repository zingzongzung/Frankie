// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/Collection.sol";
import "./NFTRandomManager.sol";
import "./libraries/NumberUtils.sol";

abstract contract NFTGenerator {
	Collection myCollection;

	NFTRandomManager nftRandomManager;

	mapping(uint => Generator.NFT) nfts;
	uint public _nextTokenId;

	function init(address collectionAddress, address nftRandomManagerAddress) internal {
		myCollection = Collection(collectionAddress);
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	function getNFTDetails(uint256 tokenId) public view returns (Generator.NFT memory) {
		return nfts[tokenId];
	}

	function startRandomProcess(uint256 tokenId, string memory name) internal {
		Generator.NFT storage myNft = nfts[tokenId];
		myNft.name = name;
		nftRandomManager.requestRandomWords(address(this), tokenId);
	}

	function copy(Generator.NFT storage target, Generator.NFT memory origin) internal {
		target.name = origin.name;
		target.genes = origin.genes;
		for (uint i = 0; i < origin.traits.length; i++) {
			target.traits.push(Generator.Trait(origin.traits[i].traitType, origin.traits[i].key, origin.traits[i].isDefined, origin.traits[i].value));
		}

		//To remove
		for (uint i = 0; i < origin.traits.length; i++) {
			target.chancesGene.push(origin.chancesGene[i]);
		}
	}

	function _generate(string memory name, uint256 tokenId, uint genes) internal {
		Generator.NFT storage myNft = nfts[tokenId];
		myNft.name = name;

		copy(nfts[tokenId], myCollection.generateNFT(genes));
	}

	function generate(uint tokenId, uint genes) external {
		copy(nfts[tokenId], myCollection.generateNFT(genes));
	}
}
