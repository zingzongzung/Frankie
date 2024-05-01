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
