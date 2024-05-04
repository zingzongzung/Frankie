// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Collection.sol";
import "../managers/NFTRandomManager.sol";
import "../libraries/NumberUtils.sol";

contract CollectionGenerator is ICollectionGenerator, AccessControl, ERC721 {
	using Strings for address;
	using Strings for uint;

	//Roles
	bytes32 public constant NFT_RANDOM_MANAGER = keccak256("NFT_RANDOM_MANAGER");
	bytes32 public constant NFT_MANAGER = keccak256("NFT_MANAGER");

	Collection private myCollection;
	NFTRandomManager private nftRandomManager;
	address private shopManagerAddress;

	string private tokenURIBaseURL;

	mapping(uint => Types.NFT) nfts;
	uint public _nextTokenId;

	constructor(address collectionAddress, address nftRandomManagerAddress, string memory _tokenURI, string memory name, string memory symbol) ERC721(name, symbol) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		tokenURIBaseURL = _tokenURI;
		myCollection = Collection(collectionAddress);
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	//Permissioned functions
	function setTokenURIBaseURL(string calldata _tokenURIBaseURL) external onlyRole(DEFAULT_ADMIN_ROLE) {
		tokenURIBaseURL = _tokenURIBaseURL;
	}

	function safeMint(address to, string calldata name) public onlyRole(NFT_MANAGER) {
		startRandomProcess(_nextTokenId, name);
		_safeMint(to, _nextTokenId);
		_nextTokenId++;
	}

	function generate(uint tokenId, uint genes) external onlyRole(NFT_RANDOM_MANAGER) {
		copy(nfts[tokenId], myCollection.generateNFT(genes));
	}

	//View Functions
	function getNFTDetails(uint256 tokenId) public view returns (Types.NFT memory) {
		return nfts[tokenId];
	}

	function getCollectionAddress() external view returns (address) {
		return address(myCollection);
	}

	function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721, IERC165) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		return string(abi.encodePacked(tokenURIBaseURL, "/", address(this).toHexString(), "/", tokenId.toString(), "/", address(myCollection).toHexString()));
	}

	//Internal Functions
	function startRandomProcess(uint256 tokenId, string memory name) internal {
		Types.NFT storage myNft = nfts[tokenId];
		myNft.name = name;
		nftRandomManager.requestRandomWords(address(this), tokenId);
	}

	function copy(Types.NFT storage target, Types.NFT memory origin) internal {
		target.genes = origin.genes;
		for (uint i = 0; i < origin.traits.length; i++) {
			target.traits.push(Types.Trait(origin.traits[i].traitType, origin.traits[i].key, origin.traits[i].isDefined, origin.traits[i].value));
		}

		//To remove
		for (uint i = 0; i < origin.traits.length; i++) {
			target.chancesGene.push(origin.chancesGene[i]);
		}
	}
}
