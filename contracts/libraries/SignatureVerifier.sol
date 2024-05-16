// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SignatureVerifier {
	using ECDSA for bytes32;

	function verifiySignature(address signer, bytes memory signature, string memory aString, uint256 number, bytes32 aBytes32) public pure returns (bool) {
		bytes32 digest = keccak256(abi.encodePacked(aString, number, aBytes32));
		bytes32 hashedMessage = MessageHashUtils.toEthSignedMessageHash(digest);
		bool isSignatureVerified = hashedMessage.recover(signature) == signer;
		return (isSignatureVerified);
	}
}
