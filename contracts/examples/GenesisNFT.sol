// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./GenesisCollection.sol";
import "../interfaces/NFTGenerator.sol";
import "../libraries/Generator.sol";

contract GenesisNFT is NFTGenerator {
	constructor(
		address initialOwner,
		address collectionAddress,
		address nftRandomManagerAddress,
		string memory name,
		string memory symbol
	) NFTGenerator(initialOwner, collectionAddress, nftRandomManagerAddress, name, symbol) {}
}
