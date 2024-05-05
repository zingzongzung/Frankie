// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../managers/random/RandomConsumerBase.sol";
import "../../libraries/NumberUtils.sol";
import "../../libraries/Roles.sol";

contract CollectionNFT is ICollectionNFT, RandomConsumerBase, AccessControl, ERC721 {
	using Strings for address;
	using Strings for uint;

	ICollectionConfig private myCollection;

	string private tokenURIBaseURL;

	mapping(uint => Types.NFT) nfts;
	uint public _nextTokenId;

	constructor(
		address collectionAddress,
		address nftRandomManagerAddress,
		string memory _tokenURI,
		string memory name,
		string memory symbol
	) ERC721(name, symbol) RandomConsumerBase(nftRandomManagerAddress) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		tokenURIBaseURL = _tokenURI;
		myCollection = ICollectionConfig(collectionAddress);
	}

	//Permissioned functions
	function setTokenURIBaseURL(string calldata _tokenURIBaseURL) external onlyRole(DEFAULT_ADMIN_ROLE) {
		tokenURIBaseURL = _tokenURIBaseURL;
	}

	function safeMint(address to, string calldata name) public onlyRole(Roles.NFT_MANAGER) {
		startRandomProcess(_nextTokenId, name);
		_safeMint(to, _nextTokenId);
		_nextTokenId++;
	}

	function generate(uint tokenId, uint genes) external override(ICollectionNFT, IRandomConsumer) onlyRole(Roles.NFT_RANDOM_MANAGER) {
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

	function getOwner(uint tokenId) external view override returns (address) {
		return ownerOf(tokenId);
	}

	function setTrait(uint256 tokenId, uint256 traitIndex, Types.Trait memory trait) external override onlyRole(Roles.NFT_MANAGER) {
		Types.NFT storage myNft = nfts[tokenId];
		myNft.traits[traitIndex] = trait;
	}

	//Internal Functions
	function startRandomProcess(uint256 tokenId, string memory name) internal {
		Types.NFT storage myNft = nfts[tokenId];
		myNft.name = name;
		requestRandom(address(this), tokenId);
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
