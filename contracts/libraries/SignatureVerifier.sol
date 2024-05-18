// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

library SignatureVerifier {
	using ECDSA for bytes32;

	function verifiySignature(address signer, bytes memory signature, string memory aString, uint256 number, bytes32 aBytes32) internal pure returns (bool) {
		bytes32 digest = keccak256(abi.encodePacked(aString, number, aBytes32));
		bytes32 hashedMessage = MessageHashUtils.toEthSignedMessageHash(digest);
		bool isSignatureVerified = hashedMessage.recover(signature) == signer;
		return (isSignatureVerified);
	}

	function verifiySignatureFromBytes32(address signer, bytes memory signature, uint256 number, bytes32 aBytes32) internal pure returns (bool) {
		bytes32 digest = keccak256(abi.encodePacked(number, aBytes32));
		bytes32 hashedMessage = MessageHashUtils.toEthSignedMessageHash(digest);
		bool isSignatureVerified = hashedMessage.recover(signature) == signer;
		return (isSignatureVerified);
	}

	function verifiySignatureFromString(address signer, bytes memory signature, uint256 number, string memory aString) internal pure returns (bool) {
		bytes32 digest = keccak256(abi.encodePacked(number, aString));
		bytes32 hashedMessage = MessageHashUtils.toEthSignedMessageHash(digest);
		bool isSignatureVerified = hashedMessage.recover(signature) == signer;
		return (isSignatureVerified);
	}
}
