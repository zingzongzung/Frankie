// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Collection.sol";
import "../managers/NFTRandomManager.sol";
import "../libraries/NumberUtils.sol";

abstract contract NFTGenerator is ERC721, Ownable {
	using Strings for address;
	using Strings for uint;
	error InvalidRandomManagerAddress(address nftRandomManagerAddress);

	Collection myCollection;
	NFTRandomManager nftRandomManager;

	string private tokenURIBaseURL;

	mapping(uint => Generator.NFT) nfts;
	uint public _nextTokenId;

	constructor(
		address initialOwner,
		address collectionAddress,
		address nftRandomManagerAddress,
		string memory name,
		string memory symbol
	) ERC721(name, symbol) Ownable(initialOwner) {
		myCollection = Collection(collectionAddress);
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	function getNFTDetails(uint256 tokenId) public view returns (Generator.NFT memory) {
		return nfts[tokenId];
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		return string(abi.encodePacked(tokenURIBaseURL, "/", address(this).toHexString(), "/", tokenId.toString()));
	}

	function setRandomManager(address nftRandomManagerAddress) external onlyOwner {
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	function setTokenURIBaseURL(string memory _tokenURIBaseURL) external onlyOwner {
		tokenURIBaseURL = _tokenURIBaseURL;
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

	/**
	 * Helper function to copy data from memory to the contract storage.
	 *
	 * @param target The NFT target in storage
	 * @param origin The NFT origin from memory
	 */
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

	/**
	 *
	 * Hellper function to help with the tests
	 * TODO to be removed once the project is stabilized
	 *
	 * @param name Name of the token
	 * @param tokenId Token id
	 * @param genes (Not so much) Random number
	 */
	function _generate(string memory name, uint256 tokenId, uint genes) internal {
		Generator.NFT storage myNft = nfts[tokenId];
		myNft.name = name;

		copy(nfts[tokenId], myCollection.generateNFT(genes));
	}

	/**
	 *
	 * This initializes the randomizer process, by setting a request on the random manager that will call VRF
	 *
	 * @param tokenId The token id we need a random number
	 * @param name The name of the new NFT
	 */
	function startRandomProcess(uint256 tokenId, string memory name) internal {
		Generator.NFT storage myNft = nfts[tokenId];
		myNft.name = name;
		nftRandomManager.requestRandomWords(address(this), tokenId);
	}

	/**
	 *
	 * This is the callback from the random manager, which will call VRF and then call this contract to proceed with the mint.
	 * This is only authorized to be called from the random manager contract
	 *
	 * @param tokenId The token id for which a random number was requested
	 * @param genes The random number which represent the genes that will be used to determine the traits that will be given to the new nft
	 */
	function generate(uint tokenId, uint genes) external onlyRandomManager {
		copy(nfts[tokenId], myCollection.generateNFT(genes));
	}

	modifier onlyRandomManager() {
		if (address(nftRandomManager) != msg.sender) {
			revert InvalidRandomManagerAddress(msg.sender);
		}
		_;
	}
}
