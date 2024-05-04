// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/ICollectionGenerator.sol";
import "../interfaces/INFTManager.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

abstract contract NFTManager is INFTManager, AccessControl, ReentrancyGuard {
	address[] managedCollectionGenerators;
	mapping(address => uint8) managedCollectionGeneratorsIndex;

	constructor() {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function _mintNFT(address nftCollectionAddress, string calldata nftName) internal onlyAuthorizedCollections(nftCollectionAddress) {
		ICollectionGenerator generator = ICollectionGenerator(nftCollectionAddress);

		generator.safeMint(msg.sender, nftName);
	}

	function addManagedCollection(address nftCollectionAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
		managedCollectionGenerators.push(nftCollectionAddress);
		managedCollectionGeneratorsIndex[nftCollectionAddress] = 1;
	}

	function getManagedCollections() external view returns (address[] memory) {
		return managedCollectionGenerators;
	}

	function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
		payable(msg.sender).transfer(address(this).balance);
	}

	modifier onlyAuthorizedCollections(address nftCollectionAddress) {
		require(managedCollectionGeneratorsIndex[nftCollectionAddress] == 1, "This collection is not managed by this");
		_;
	}
}
