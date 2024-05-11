// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRandomConsumer {
	function handleVRFResponse(uint tokenId, uint[] memory randomWords) external;
}
