// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";

import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../../../libraries/Roles.sol";
import "./ISurfForecastServiceConsumer.sol";

contract SurfForecastService is FunctionsClient, AccessControl {
	using FunctionsRequest for FunctionsRequest.Request;

	string source;
	bytes encryptedSecretsUrls;
	uint32 gasLimit;
	bytes32 donID;
	uint64 subscriptionId;

	struct RequestStatus {
		bool fulfilled; // whether the request has been successfully fulfilled
		bool exists; // whether a requestId exists
		address requestor;
	}
	mapping(bytes32 => RequestStatus) public s_requests;

	constructor(address router) FunctionsClient(router) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function setForecastServiceConfig(string memory _source, bytes memory _encryptedSecretsUrls, uint32 _gasLimit, bytes32 _donID, uint64 _subscriptionId) public {
		source = _source;
		if (_encryptedSecretsUrls.length > 0) encryptedSecretsUrls = _encryptedSecretsUrls;
		gasLimit = _gasLimit;
		donID = _donID;
		subscriptionId = _subscriptionId;
	}

	function sendRequest(address requestor) external onlyRole(Roles.SURF_FORECAST_CONSUMER) returns (bytes32 requestId) {
		FunctionsRequest.Request memory req;
		req.initializeRequestForInlineJavaScript(source);
		if (encryptedSecretsUrls.length > 0) req.addSecretsReference(encryptedSecretsUrls);
		requestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donID);
		s_requests[requestId] = RequestStatus(false, true, requestor);
	}

	function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
		require(s_requests[requestId].exists, "request not found");
		require(!s_requests[requestId].fulfilled, "request already fulfilled");
		ISurfForecastServiceConsumer requestHandler = ISurfForecastServiceConsumer(s_requests[requestId].requestor);
		requestHandler.handleForecastServiceResponse(requestId, response);
	}
}
