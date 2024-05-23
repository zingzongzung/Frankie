// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../managers/random/RandomConsumerBase.sol";
import "../../managers/nfts/PassManager.sol";

import "./ICollectionNFT.sol";

contract CollectionNFT is ICollectionNFT, RandomConsumerBase, AccessControl, ERC721 {
	using Strings for address;
	using Strings for uint;

	event TokenMinted(address, uint);

	ICollectionConfig private collectionConfig;

	string private tokenURIBaseURL;

	mapping(uint => Types.NFT) private nftDetails;
	mapping(uint => mapping(bytes32 => Types.Trait)) private nftTraits;
	mapping(uint => mapping(uint => bytes32)) private nftTraitsKeys;
	mapping(uint => uint) private nftTraitsSize;
	mapping(uint => address) private tokenMinterAddress;

	uint public _nextTokenId;

	uint private dynamicTraitsSize;
	mapping(uint => Types.Trait) private dynamicTraits;

	constructor(
		address collectionAddress,
		address nftRandomManagerAddress,
		string memory _tokenURI,
		string memory name,
		string memory symbol,
		bytes memory signature
	) ERC721(name, symbol) RandomConsumerBase(nftRandomManagerAddress) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		tokenURIBaseURL = _tokenURI;
		collectionConfig = ICollectionConfig(collectionAddress);
		(bool isPass, Types.Pass memory pass, PassManager passManager) = collectionConfig.getPassSettings();
		//If is not a pass
		if (!isPass) {
			passManager.setPassCollectionAddress(pass.passAddress, pass.passId, address(this), signature);
		}
		emit TraitMetadataURIUpdated();
	}

	//Permissioned functions
	function setTokenURIBaseURL(string calldata _tokenURIBaseURL) external onlyRole(DEFAULT_ADMIN_ROLE) {
		tokenURIBaseURL = _tokenURIBaseURL;
	}

	function safeMint(address to, string calldata name) public onlyRole(Roles.NFT_MANAGER) {
		tokenMinterAddress[_nextTokenId] = to;

		if (collectionConfig.hasRandomTraits()) {
			startRandomProcess(_nextTokenId, name);
		} else {
			/* this needs to be improved , just reusing the same logic to populate the nft becase of time constraints */
			_generateAndMintNFT(99999999999, _nextTokenId);
		}

		_nextTokenId++;
	}

	function _generateAndMintNFT(uint genes, uint tokenId) internal {
		_safeMint(tokenMinterAddress[tokenId], tokenId);

		Types.Trait[] memory traits = collectionConfig.generateNFT(genes);
		nftTraitsSize[tokenId] = traits.length;
		bytes32 currentTraitKey;
		for (uint currentIndex = 0; currentIndex < traits.length; currentIndex++) {
			currentTraitKey = traits[currentIndex].key;
			nftTraits[tokenId][currentTraitKey] = traits[currentIndex];
			nftTraitsKeys[tokenId][currentIndex] = currentTraitKey;
		}
		emit TokenMinted(tokenMinterAddress[tokenId], tokenId);
		delete tokenMinterAddress[tokenId];
	}

	function handleVRFResponse(uint tokenId, uint[] memory randomWords) external override onlyRole(Roles.NFT_RANDOM_MANAGER) {
		_generateAndMintNFT(randomWords[0], tokenId);
	}

	function getTraitByKey(uint256 tokenId, bytes32 traitKey) external view returns (Types.Trait memory traitValue) {
		return nftTraits[tokenId][traitKey];
	}

	function getNFTDetails(uint256 tokenId) public view returns (Types.NFT memory, Types.Trait[] memory result) {
		result = new Types.Trait[](nftTraitsSize[tokenId]);
		bytes32 currentTraitKey;
		for (uint currentIndex = 0; currentIndex < nftTraitsSize[tokenId]; currentIndex++) {
			currentTraitKey = nftTraitsKeys[tokenId][currentIndex];
			result[currentIndex] = nftTraits[tokenId][currentTraitKey];
		}
		return (nftDetails[tokenId], result);
	}

	function getCollectionAddress() external view returns (address) {
		return address(collectionConfig);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		return string(abi.encodePacked(tokenURIBaseURL, "/GetTokenURI/", address(this).toHexString(), "/", tokenId.toString(), "/", address(collectionConfig).toHexString()));
	}

	/** Dynamic NFT */
	function getTraitValue(uint256 tokenId, bytes32 traitKey) external view returns (bytes32 traitValue) {
		return nftTraits[tokenId][traitKey].value;
	}

	function getTraitValues(uint256 tokenId, bytes32[] calldata traitKeys) external view returns (bytes32[] memory traitValues) {
		traitValues = new bytes32[](traitKeys.length);
		for (uint i; i < traitKeys.length; i++) {
			traitValues[i] = nftTraits[tokenId][traitKeys[i]].value;
		}
	}

	function getTraitMetadataURI() external view returns (string memory uri) {
		return string(abi.encodePacked(tokenURIBaseURL, "/GetTraitMetadataURI/", address(this).toHexString()));
	}

	/* Setters */
	function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 traitValue) external {
		//Not using this for now
	}

	function getOwner(uint tokenId) external view override returns (address) {
		return ownerOf(tokenId);
	}

	function setTraits(uint256 tokenId, Types.Trait[] memory traits) external onlyRole(Roles.NFT_MANAGER) {
		for (uint256 traitIndex; traitIndex < traits.length; traitIndex++) {
			_setTrait(tokenId, traits[traitIndex]);
		}
	}

	function _setTrait(uint256 tokenId, Types.Trait memory trait) internal {
		bytes32 traitKey = trait.key;

		if (!nftTraits[tokenId][traitKey].isDefined) {
			uint256 traitsSize = nftTraitsSize[tokenId] + 1;
			nftTraitsSize[tokenId] = traitsSize;
			nftTraitsKeys[tokenId][traitsSize - 1] = traitKey;
			handleNewDynamicTrait(trait);
		}
		nftTraits[tokenId][traitKey] = trait;
		emit MetadataUpdate(tokenId);
		emit TraitUpdated(traitKey, tokenId, trait.value);
	}

	function setTrait(uint256 tokenId, Types.Trait memory trait) external override onlyRole(Roles.NFT_MANAGER) {
		_setTrait(tokenId, trait);
	}

	/**
	 *
	 * Token ownership
	 *
	 */
	function getTokensOwnedBy(address wallet) external view returns (uint256[] memory) {
		uint256 balance = balanceOf(wallet);
		uint256[] memory tokensOwned = new uint256[](balance);
		uint tokenId;
		for (uint256 i = 0; i < balance; i++) {
			tokenId = tokenOfOwnerByIndexRecursive(wallet, i, tokenId);
			tokensOwned[i] = tokenId;
		}
		return tokensOwned;
	}

	function tokenOfOwnerByIndexRecursive(address owner, uint256 currentIndex, uint256 lastToken) internal view returns (uint256) {
		if (currentIndex < lastToken) {
			currentIndex = lastToken + 1;
		}
		return tokenOfOwnerByIndexRecursive(owner, currentIndex);
	}

	function tokenOfOwnerByIndexRecursive(address owner, uint256 currentIndex) internal view returns (uint256) {
		if (ownerOf(currentIndex) == owner) {
			return currentIndex;
		} else {
			return tokenOfOwnerByIndexRecursive(owner, currentIndex + 1);
		}
	}

	//Internal Functions
	function startRandomProcess(uint256 tokenId, string memory name) internal {
		Types.NFT storage myNft = nftDetails[tokenId];
		myNft.name = name;
		requestRandom(address(this), tokenId, 1);
	}

	function copy(Types.Trait[] storage target, Types.Trait[] memory origin) internal {
		for (uint i = 0; i < origin.length; i++) {
			target.push(Types.Trait(origin[i].isDefined, origin[i].traitType, origin[i].key, origin[i].value));
		}
	}

	//Post added traits handling
	function handleNewDynamicTrait(Types.Trait memory trait) internal {
		dynamicTraits[dynamicTraitsSize] = trait;
		dynamicTraitsSize++;

		emit TraitMetadataURIUpdated();
	}

	function getDynamicTraits() external view returns (Types.Trait[] memory traits) {
		traits = new Types.Trait[](dynamicTraitsSize);
		for (uint index; index < dynamicTraitsSize; index++) {
			traits[index] = dynamicTraits[index];
		}
	}

	function getCollectionOwner() external view override returns (address) {
		return collectionConfig.getCollectionOwner();
	}

	function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721, IERC165) returns (bool) {
		return super.supportsInterface(interfaceId);
	}
}
