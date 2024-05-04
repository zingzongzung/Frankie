// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Collection.sol";
import "../managers/NFTRandomManager.sol";
import "../libraries/NumberUtils.sol";

abstract contract CollectionGenerator is AccessControl, ERC721 {
	using Strings for address;
	using Strings for uint;

	//Roles
	bytes32 public constant NFT_RANDOM_MANAGER = keccak256("NFT_RANDOM_MANAGER");
	bytes32 public constant NFT_SHOP_MANAGER = keccak256("NFT_SHOP_MANAGER");

	Collection private myCollection;
	NFTRandomManager private nftRandomManager;
	address private shopManagerAddress;

	string private tokenURIBaseURL;

	mapping(uint => Generator.NFT) nfts;
	uint public _nextTokenId;

	constructor(address collectionAddress, address nftRandomManagerAddress, string memory _tokenURI, string memory name, string memory symbol) ERC721(name, symbol) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		tokenURIBaseURL = _tokenURI;
		myCollection = Collection(collectionAddress);
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	function getNFTDetails(uint256 tokenId) public view returns (Generator.NFT memory) {
		return nfts[tokenId];
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		return string(abi.encodePacked(tokenURIBaseURL, "/", address(this).toHexString(), "/", tokenId.toString(), "/", address(myCollection).toHexString()));
	}

	function setTokenURIBaseURL(string calldata _tokenURIBaseURL) external onlyRole(DEFAULT_ADMIN_ROLE) {
		tokenURIBaseURL = _tokenURIBaseURL;
	}

	function getCollectionAddress() external view returns (address) {
		return address(myCollection);
	}

	/**
	 *
	 * @param to The mint to
	 * @param name The name of the token
	 */
	function safeMint(address to, string calldata name) public onlyRole(NFT_SHOP_MANAGER) {
		startRandomProcess(_nextTokenId, name);
		_safeMint(to, _nextTokenId);
		_nextTokenId++;
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
	function generate(uint tokenId, uint genes) external onlyRole(NFT_RANDOM_MANAGER) {
		copy(nfts[tokenId], myCollection.generateNFT(genes));
	}

	/**
	 * Helper function to copy data from memory to the contract storage.
	 *
	 * @param target The NFT target in storage
	 * @param origin The NFT origin from memory
	 */
	function copy(Generator.NFT storage target, Generator.NFT memory origin) internal {
		target.genes = origin.genes;
		for (uint i = 0; i < origin.traits.length; i++) {
			target.traits.push(Generator.Trait(origin.traits[i].traitType, origin.traits[i].key, origin.traits[i].isDefined, origin.traits[i].value));
		}

		//To remove
		for (uint i = 0; i < origin.traits.length; i++) {
			target.chancesGene.push(origin.chancesGene[i]);
		}
	}

	function supportsInterface(bytes4 interfaceId) public view override(ERC721, AccessControl) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
