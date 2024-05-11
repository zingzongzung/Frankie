// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Roles {
	//Roles
	bytes32 public constant NFT_RANDOM_MANAGER = keccak256("NFT_RANDOM_MANAGER");
	bytes32 public constant NFT_MANAGER = keccak256("NFT_MANAGER");
}
