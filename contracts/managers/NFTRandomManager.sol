// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/CollectionGenerator.sol";

contract NFTRandomManager is VRFConsumerBaseV2, AccessControl {
	bytes32 public constant NFT_RANDOM_MANAGER = keccak256("NFT_RANDOM_MANAGER");
	CollectionGenerator nftGenerator;

	// VRF
	event RequestSent(uint256 requestId, uint32 numWords);
	event RequestFulfilled(uint256 requestId, uint256[] randomWords);

	struct RequestStatus {
		bool fulfilled; // whether the request has been successfully fulfilled
		bool exists; // whether a requestId exists
		uint256[] randomWords;
		address requestor;
		uint256 tokenId;
	}
	mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

	// Fuji coordinator
	// https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/
	VRFCoordinatorV2Interface COORDINATOR;
	address vrfCoordinator = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
	bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
	uint32 callbackGasLimit = 2500000;
	uint16 requestConfirmations = 3;
	uint32 numWords = 1;

	// past requests Ids.
	uint256[] public requestIds;
	uint256 public lastRequestId;
	uint256[] public lastRandomWords;

	// Your subscription ID.
	uint64 public s_subscriptionId;

	constructor(uint64 subscriptionId) VRFConsumerBaseV2(vrfCoordinator) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
		s_subscriptionId = subscriptionId;
		safeMint(msg.sender, 0);
	}

	function safeMint(address to, uint256 charId) public {}

	function getNFTRandomManagerRole() external pure returns (bytes32) {
		return NFT_RANDOM_MANAGER;
	}

	function requestRandomWords(address requestor, uint256 tokenId) external onlyRole(NFT_RANDOM_MANAGER) returns (uint256 requestId) {
		// Will revert if subscription is not set and funded.
		requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, numWords);
		s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false, requestor: requestor, tokenId: tokenId});
		requestIds.push(requestId);
		lastRequestId = requestId;
		emit RequestSent(requestId, numWords);

		return requestId;
	}

	function fulfillRandomWords(uint256 _requestId /* requestId */, uint256[] memory _randomWords) internal override {
		require(s_requests[_requestId].exists, "request not found");
		s_requests[_requestId].fulfilled = true;
		s_requests[_requestId].randomWords = _randomWords;
		nftGenerator = CollectionGenerator(s_requests[_requestId].requestor);
		nftGenerator.generate(s_requests[_requestId].tokenId, _randomWords[0]);
	}

	function getRequest(uint256 _requestId) external view returns (RequestStatus memory rs) {
		return s_requests[_requestId];
	}

	function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {}
}