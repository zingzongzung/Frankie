// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

library SignerTest {
	using MessageHashUtils for bytes32;
	using ECDSA for bytes32;

	function recoverSigner(bytes32 message, bytes memory signature) external pure returns (address) {
		return message.recover(signature);
	}
}
