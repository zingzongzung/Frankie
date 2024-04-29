// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./collections/GenesisCollection.sol";
import "./NFTGenerator.sol";

contract BasicNFT is ERC721, Ownable, NFTGenerator {
	string private host = "https://outsystems";

	function getNFTDetails(uint256 tokenId) public view returns (NFT memory) {
		return nfts[tokenId];
	}

	function getTokenURI() external view returns (string memory result) {}

	constructor(address initialOwner, address collectionAddress) ERC721("BasicNFT", "teste") Ownable(initialOwner) {
		setCollectionAddress(collectionAddress);
	}

	function safeMint(address to, uint256 randomNumber, string memory name) public onlyOwner {
		generate(name, _nextTokenId, randomNumber);
		_safeMint(to, _nextTokenId);
		_nextTokenId++;
	}
}
