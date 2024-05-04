// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GenesisCollection.sol";
import "../interfaces/CollectionGenerator.sol";
import "../libraries/Generator.sol";

contract GenesisGenerator is CollectionGenerator {
	constructor(
		address collectionAddress,
		address nftRandomManagerAddress,
		string memory _tokenUri,
		string memory name,
		string memory symbol
	) CollectionGenerator(collectionAddress, nftRandomManagerAddress, _tokenUri, name, symbol) {}
}
