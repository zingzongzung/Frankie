// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./collections/GenesisCollection.sol";
import "./NFTGenerator.sol";
import "./libraries/Generator.sol";

contract BasicNFT is ERC721, Ownable, NFTGenerator {
	string private host = "https://outsystems";

	constructor(address initialOwner, address collectionAddress, address nftRandomManagerAddress) ERC721("BasicNFT", "teste") Ownable(initialOwner) {
		init(collectionAddress, nftRandomManagerAddress);
	}

	uint examplesIndex;
	mapping(uint => Generator.NFT) examples;

	function copy(Generator.NFT storage target, Generator.NFT memory origin) internal {
		target.name = origin.name;
		for (uint i = 0; i < origin.traits.length; i++) {
			target.traits.push(Generator.Trait(origin.traits[i].traitType, origin.traits[i].key, origin.traits[i].isDefined, origin.traits[i].value));
		}
	}

	function addExample() external {
		copy(examples[examplesIndex], Generator.generateNFT(myCollection, 4567867867856785995002450));
		examplesIndex++;
	}

	function example(uint index) external view returns (Generator.NFT memory) {
		return examples[index];
	}

	function getTokenURI() external view returns (string memory result) {}

	function setRandomManager(address nftRandomManagerAddress) external onlyOwner {
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	function safeMint(address to, string memory name) public onlyOwner {
		startRandomProcess(_nextTokenId, name);
		_safeMint(to, _nextTokenId);
		_nextTokenId++;
	}

	function safeMintTest(address to, uint256 randomNumber, string memory name) public onlyOwner {
		_generate(name, _nextTokenId, randomNumber);
		_safeMint(to, _nextTokenId);
		_nextTokenId++;
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		return super.tokenURI(tokenId);
	}
}
