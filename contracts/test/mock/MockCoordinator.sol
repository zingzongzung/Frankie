// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract MockCoordinator is VRFCoordinatorV2Interface {
	function getRequestConfig() external view override returns (uint16, uint32, bytes32[] memory) {}

	function requestRandomWords(
		bytes32 keyHash,
		uint64 subId,
		uint16 minimumRequestConfirmations,
		uint32 callbackGasLimit,
		uint32 numWords
	) external override returns (uint256 requestId) {
		return 0;
	}

	function createSubscription() external override returns (uint64 subId) {}

	function getSubscription(uint64 subId) external view override returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers) {}

	function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external override {}

	function acceptSubscriptionOwnerTransfer(uint64 subId) external override {}

	function addConsumer(uint64 subId, address consumer) external override {}

	function removeConsumer(uint64 subId, address consumer) external override {}

	function cancelSubscription(uint64 subId, address to) external override {}

	function pendingRequestExists(uint64 subId) external view override returns (bool) {}

	function mockVRFCoordinatorResponse(address vrfRequestorAddress, uint256[] calldata simulatedRandomWords) external {
		VRFConsumerBaseV2 vrfConsumarBase = VRFConsumerBaseV2(vrfRequestorAddress);
		vrfConsumarBase.rawFulfillRandomWords(0, simulatedRandomWords);
	}
}
