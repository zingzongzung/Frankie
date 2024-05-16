// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Constants {
	bytes32 public constant PASS_LABEL = bytes32(abi.encodePacked("Pass"));
	bytes32 public constant PASS_GENESIS_LABEL = bytes32(abi.encodePacked("Genesis"));
	bytes32 public constant PASS_COLLECTION_LABEL = bytes32(abi.encodePacked("Collection Name"));
	bytes32 public constant PASS_COLLECTION_ADDRESS_LABEL = bytes32(abi.encodePacked("Collection Address"));
}
