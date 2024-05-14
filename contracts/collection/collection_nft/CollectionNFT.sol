// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../managers/random/RandomConsumerBase.sol";

import "./ICollectionNFT.sol";

contract CollectionNFT is ICollectionNFT, RandomConsumerBase, AccessControl, ERC721 {
	using Strings for address;
	using Strings for uint;

	ICollectionConfig private collectionConfig;

	string private tokenURIBaseURL;

	mapping(uint => Types.NFT) nftDetails;
	mapping(uint => mapping(bytes32 => Types.Trait)) nftTraits;
	mapping(uint => mapping(uint => bytes32)) nftTraitsKeys;
	mapping(uint => uint) nftTraitsSize;

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
		collectionConfig = ICollectionConfig(collectionAddress);
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

	function handleVRFResponse(uint tokenId, uint[] memory randomWords) external override onlyRole(Roles.NFT_RANDOM_MANAGER) {
		uint256 genes = randomWords[0];
		Types.Trait[] memory traits = collectionConfig.generateNFT(genes);
		nftTraitsSize[tokenId] = traits.length;
		bytes32 currentTraitKey;
		for (uint currentIndex = 0; currentIndex < traits.length; currentIndex++) {
			currentTraitKey = traits[currentIndex].key;
			nftTraits[tokenId][currentTraitKey] = traits[currentIndex];
			nftTraitsKeys[tokenId][currentIndex] = currentTraitKey;
			emit TraitUpdated(currentTraitKey, tokenId, traits[currentIndex].value);
		}
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

	function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721, IERC165) returns (bool) {
		return super.supportsInterface(interfaceId);
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
		return string(abi.encodePacked(tokenURIBaseURL, "/GetTraitMetadataURI/", address(collectionConfig).toHexString()));
	}

	/* Setters */
	function setTrait(uint256 tokenId, bytes32 traitKey, bytes32 traitValue) external {
		//Not using this for now
	}

	function getOwner(uint tokenId) external view override returns (address) {
		return ownerOf(tokenId);
	}

	function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
		// Bytes buffer to hold the string characters
		bytes memory buffer = new bytes(32);
		uint256 charCount = 0;

		// Iterate through each byte of the bytes32
		for (uint256 i = 0; i < 32; i++) {
			// Break if the padding starts
			if (_bytes32[i] == 0) {
				break;
			}
			// Place the character into the buffer
			buffer[charCount] = _bytes32[i];
			charCount++;
		}

		// Resize the buffer to the actual length and convert it to a string
		bytes memory realBuffer = new bytes(charCount);
		for (uint256 i = 0; i < charCount; i++) {
			realBuffer[i] = buffer[i];
		}

		return string(realBuffer);
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
		}
		nftTraits[tokenId][traitKey] = trait;
		emit TraitUpdated(traitKey, tokenId, trait.value);
	}

	function setTrait(uint256 tokenId, Types.Trait memory trait) external override onlyRole(Roles.NFT_MANAGER) {
		_setTrait(tokenId, trait);
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
		Types.NFT storage myNft = nftDetails[tokenId];
		myNft.name = name;
		requestRandom(address(this), tokenId, 1);
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

	function copy(Types.Trait[] storage target, Types.Trait[] memory origin) internal {
		for (uint i = 0; i < origin.length; i++) {
			target.push(Types.Trait(origin[i].isDefined, origin[i].traitType, origin[i].key, origin[i].value));
		}
	}
}
