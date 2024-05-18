// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji
import "../libraries/SignatureVerifier.sol";

contract TestSignatureVerifier {
	function verifiySignature(address signer, bytes memory signature, string memory aString, uint256 number, bytes32 aBytes32) external pure returns (bool) {
		return SignatureVerifier.verifiySignature(signer, signature, aString, number, aBytes32);
	}

	function verifiySignatureFromBytes32(address signer, bytes memory signature, uint256 number, bytes32 aBytes32) external pure returns (bool) {
		return SignatureVerifier.verifiySignatureFromBytes32(signer, signature, number, aBytes32);
	}

	function verifiySignatureFromString(address signer, bytes memory signature, uint256 number, string memory aString) external pure returns (bool) {
		return SignatureVerifier.verifiySignatureFromString(signer, signature, number, aString);
	}
}
