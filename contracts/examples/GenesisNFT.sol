// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GenesisCollection.sol";
import "../interfaces/CollectionGenerator.sol";
import "../libraries/Generator.sol";

contract GenesisNFT is CollectionGenerator {
	constructor(
		address initialOwner,
		address collectionAddress,
		address nftRandomManagerAddress,
		string memory name,
		string memory symbol
	) CollectionGenerator(initialOwner, collectionAddress, nftRandomManagerAddress, name, symbol) {}
}
