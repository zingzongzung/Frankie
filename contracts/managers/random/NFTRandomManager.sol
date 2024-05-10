// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../collection/collection_nft/ICollectionNFT.sol";
import "../../libraries/Roles.sol";

contract NFTRandomManager is VRFConsumerBaseV2, AccessControl {
	ICollectionNFT nftGenerator;

	// VRF
	event RequestSent(uint256 requestId, uint32 numWords);
	event RequestFulfilled(uint256 requestId, uint256[] randomWords);

	struct RequestStatus {
		bool fulfilled; // whether the request has been successfully fulfilled
		bool exists; // whether a requestId exists
		address requestor;
		uint256 tokenId;
	}
	mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */

	// Fuji coordinator
	// https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/
	VRFCoordinatorV2Interface COORDINATOR;
	//address vrfCoordinator; Fuji = 0x2eD832Ba664535e5886b75D64C46EB9a228C2610;
	bytes32 keyHash; // Fuji = = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;
	uint32 callbackGasLimit = 2500000;
	uint16 requestConfirmations = 3;
	uint32 numWords = 1;

	// past requests Ids.
	uint256[] public requestIds;

	// Your subscription ID.
	uint64 public s_subscriptionId;

	constructor(uint64 subscriptionId, address vrfCoordinatorAddress, bytes32 _keyHash) VRFConsumerBaseV2(vrfCoordinatorAddress) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinatorAddress);
		s_subscriptionId = subscriptionId;
		keyHash = _keyHash;
	}

	function requestRandomWords(address requestor, uint256 tokenId, uint8 _numWords) external onlyRole(Roles.NFT_RANDOM_MANAGER) returns (uint256 requestId) {
		// Will revert if subscription is not set and funded.
		requestId = COORDINATOR.requestRandomWords(keyHash, s_subscriptionId, requestConfirmations, callbackGasLimit, _numWords);
		s_requests[requestId] = RequestStatus({exists: true, fulfilled: false, requestor: requestor, tokenId: tokenId});
		requestIds.push(requestId);
		emit RequestSent(requestId, _numWords);

		return requestId;
	}

	function fulfillRandomWords(uint256 _requestId /* requestId */, uint256[] memory _randomWords) internal override {
		require(s_requests[_requestId].exists, "request not found");
		s_requests[_requestId].fulfilled = true;
		nftGenerator = ICollectionNFT(s_requests[_requestId].requestor);
		nftGenerator.generate(s_requests[_requestId].tokenId, _randomWords);
	}

	function getRequest(uint256 _requestId) external view returns (RequestStatus memory rs) {
		return s_requests[_requestId];
	}

	function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {}
}
