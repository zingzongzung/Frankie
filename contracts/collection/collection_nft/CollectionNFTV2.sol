// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../managers/random/RandomConsumerBase.sol";
import "../../libraries/NumberUtils.sol";
import "../../libraries/Roles.sol";
import "./IERC7496.sol";

import "./ICollectionNFTV2.sol";

contract CollectionNFTV2 is ICollectionNFTV2, RandomConsumerBase, AccessControl, ERC721, IERC7496 {
	using Strings for address;
	using Strings for uint;

	ICollectionConfigV2 private collectionConfig;

	string private tokenURIBaseURL;

	mapping(uint => Types.NFTV2) nfts;
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
		collectionConfig = ICollectionConfigV2(collectionAddress);
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

	function generate(uint tokenId, uint genes) external override(ICollectionNFTV2, IRandomConsumer) onlyRole(Roles.NFT_RANDOM_MANAGER) {
		copy(nfts[tokenId], collectionConfig.generateNFT(genes));

		emit TraitMetadataURIUpdated();
	}

	function getNFTDetails(uint256 tokenId) public view returns (Types.NFTV2 memory) {
		return nfts[tokenId];
	}

	function getCollectionAddress() external view returns (address) {
		return address(collectionConfig);
	}

	function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721, IERC165) returns (bool) {
		return super.supportsInterface(interfaceId);
	}

	function tokenURI(uint256 tokenId) public view override(ERC721) returns (string memory) {
		return string(abi.encodePacked(tokenURIBaseURL, "/GetTokenURI", address(this).toHexString(), "/", tokenId.toString(), "/", address(collectionConfig).toHexString()));
	}

	function _getTraitValue(uint256 tokenId, bytes32 traitKey) internal view returns (bytes32 traitValue) {
		// uint8 collectionConfigTraitKey = collectionConfig.getTraitIndexByKey(traitKey);
		// Types.NFTV2 storage nft = nfts[tokenId];
		// Types.TraitV2 memory trait = nft.traits[collectionConfigTraitKey];
		// if (trait.isDefined) {
		// 	if (trait.traitType == Types.TraitType.Number) {
		// 		traitValue = keccak256(abi.encodePacked(trait.value));
		// 	} else if (trait.traitType == Types.TraitType.Options || trait.traitType == Types.TraitType.OptionsWithImage) {
		// 		traitValue = keccak256(abi.encodePacked(collectionConfig.getTraitOptionsLabel(collectionConfigTraitKey, trait.value)));
		// 	} else if (trait.traitType == Types.TraitType.Number) {
		// 		//traitValue = keccak256(abi.encodePacked(trait.textValue));
		// 	}
		// }
	}

	/** Dynamic NFT */
	function getTraitValue(uint256 tokenId, bytes32 traitKey) external view returns (bytes32 traitValue) {
		return _getTraitValue(tokenId, traitKey);
	}

	function getTraitValues(uint256 tokenId, bytes32[] calldata traitKeys) external view returns (bytes32[] memory traitValues) {
		traitValues = new bytes32[](traitKeys.length);
		for (uint i; i < traitKeys.length; i++) {
			traitValues[i] = _getTraitValue(tokenId, traitKeys[i]);
		}
	}

	function getTraitMetadataURI() external view returns (string memory uri) {
		return string(abi.encodePacked(tokenURIBaseURL, "/GetTraitMetadataURI/", address(collectionConfig).toHexString()));
	}

	/* Setters */
	function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 traitValue) external {
		//Not using this for now
	}

	function getOwner(uint tokenId) external view override returns (address) {
		return ownerOf(tokenId);
	}

	function setTrait(uint256 tokenId, uint256 traitIndex, Types.TraitV2 memory trait) external override onlyRole(Roles.NFT_MANAGER) {
		Types.NFTV2 storage myNft = nfts[tokenId];
		myNft.traits[traitIndex] = trait;

		// bytes32 traitKey = keccak256(abi.encodePacked(collectionConfig.getTraitLabel(trait.key)));
		// bytes32 traitValue;
		// if (trait.traitType == Types.TraitV2Type.Number) {
		// 	traitValue = keccak256(abi.encodePacked(trait.value));
		// } else if (trait.traitType == Types.TraitV2Type.Options || trait.traitType == Types.TraitV2Type.OptionsWithImage) {
		// 	traitValue = keccak256(abi.encodePacked(collectionConfig.getTraitOptionsLabel(trait.key, trait.value)));
		// } else if (trait.traitType == Types.TraitV2Type.Number) {
		// 	//traitValue = keccak256(abi.encodePacked(trait.textValue));
		// }

		// emit TraitUpdated(traitKey, tokenId, traitValue);
	}

	function getTokensOwnedBy(address wallet) external view returns (uint256[] memory) {
		uint256 balance = balanceOf(wallet);
		uint256[] memory tokensOwned = new uint256[](balance);

		for (uint256 i = 0; i < balance; i++) {
			tokensOwned[i] = tokenOfOwnerByIndex(wallet, i);
		}

		return tokensOwned;
	}

	//Internal Functions
	function startRandomProcess(uint256 tokenId, string memory name) internal {
		Types.NFTV2 storage myNft = nfts[tokenId];
		myNft.name = name;
		requestRandom(address(this), tokenId);
	}

	function tokenOfOwnerByIndex(address owner, uint startIndex) internal view returns (uint256) {
		return tokenOfOwnerByIndexRecursive(owner, startIndex);
	}

	function tokenOfOwnerByIndexRecursive(address owner, uint256 currentIndex) internal view returns (uint256) {
		if (ownerOf(currentIndex) == owner) {
			return currentIndex;
		} else {
			return tokenOfOwnerByIndexRecursive(owner, currentIndex + 1);
		}
	}

	function copy(Types.NFTV2 storage target, Types.NFTV2 memory origin) internal {
		target.genes = origin.genes;
		for (uint i = 0; i < origin.traits.length; i++) {
			target.traits.push(Types.TraitV2(origin.traits[i].isDefined, origin.traits[i].traitType, origin.traits[i].key, origin.traits[i].value));
		}

		//To remove
		for (uint i = 0; i < origin.traits.length; i++) {
			target.chancesGene.push(origin.chancesGene[i]);
		}
	}
}
