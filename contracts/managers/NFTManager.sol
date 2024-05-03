// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/CollectionGenerator.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTManager is Ownable, ReentrancyGuard {
	address[] managedCollectionGenerators;
	mapping(address => uint8) managedCollectionGeneratorsIndex;

	address _owner;

	constructor(address owner) Ownable(owner) {
		_owner;
	}

	uint lastReceivedAmount;

	function getLastReceivedAmount() external view returns (uint) {
		return lastReceivedAmount;
	}

	function mintNFT(address nftCollectionAddress, string calldata nftName) public payable virtual {
		//require(msg.value >= 100000, "Not enough funds sent!");
		lastReceivedAmount = msg.value;
		require(managedCollectionGeneratorsIndex[nftCollectionAddress] == 1, "This collection was not authorized");
		CollectionGenerator generator = CollectionGenerator(nftCollectionAddress);
		generator.safeMint(msg.sender, nftName);
	}

	function addManagedCollection(address nftCollectionAddress) external onlyOwner {
		managedCollectionGenerators.push(nftCollectionAddress);
		managedCollectionGeneratorsIndex[nftCollectionAddress] = 1;
	}

	function getManagedCollections() external view returns (address[] memory) {
		return managedCollectionGenerators;
	}

	function withdraw() external onlyOwner {
		payable(_owner).transfer(address(this).balance);
	}
}
