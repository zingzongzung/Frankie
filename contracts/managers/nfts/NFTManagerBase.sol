// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "../../collection/collection_nft/ICollectionNFT.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./INFTManager.sol";

abstract contract NFTManagerBase is INFTManager, AccessControl, ReentrancyGuard {
	using Strings for address;
	mapping(address => bool) managedCollections;

	constructor() {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function _mintNFT(address nftCollectionAddress, string calldata nftName) internal {
		ICollectionNFT collection = getCollectionContract(nftCollectionAddress);

		collection.safeMint(msg.sender, nftName);
	}

	function addManagedCollection(address nftCollectionAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
		managedCollections[nftCollectionAddress] = true;
	}

	function isCollectionManaged(address nftCollectionAddress) external view returns (bool) {
		return managedCollections[nftCollectionAddress];
	}

	function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
		payable(msg.sender).transfer(address(this).balance);
	}

	//internal
	function getCollectionContract(address nftCollectionAddress) internal pure returns (ICollectionNFT collection) {
		collection = ICollectionNFT(nftCollectionAddress);
	}

	function getCollectionConfigContract(ICollectionNFT collection) internal view returns (ICollectionConfig collectionConfig) {
		collectionConfig = ICollectionConfig(collection.getCollectionAddress());
	}

	modifier onlyAuthorizedCollections(address nftCollectionAddress) {
		require(managedCollections[nftCollectionAddress], string(abi.encodePacked("Collection not managed: ", nftCollectionAddress.toHexString())));
		_;
	}
}
