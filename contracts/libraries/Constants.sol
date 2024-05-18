// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Constants {
	bytes32 public constant PASS_LABEL = bytes32(abi.encodePacked("Pass"));
	bytes32 public constant PASS_GENESIS_LABEL = bytes32(abi.encodePacked("Genesis"));
	bytes32 public constant PASS_COLLECTION_LABEL = bytes32(abi.encodePacked("Collection Name"));
	bytes32 public constant PASS_COLLECTION_ADDRESS_LABEL = bytes32(abi.encodePacked("Collection Address"));
	bytes32 public constant PASS_IMAGE_KEY = bytes32(abi.encodePacked("Pass Version"));
	bytes32 public constant PASS_IMAGE_VALUE = bytes32(abi.encodePacked("Origin"));
	string public constant PASS_IMAGE_HASH = "D7F40762F1D776532086E6F8D5F31549";
}
