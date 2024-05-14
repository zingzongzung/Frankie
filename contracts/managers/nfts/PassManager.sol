// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "./NFTManagerBase.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "../../libraries/Types.sol";
import "../../libraries/Constants.sol";
import "../../libraries/Utils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract PassManager is NFTManagerBase {
	using ECDSA for bytes32;
	AggregatorV3Interface internal dataFeed;

	//mapping(address => uint[]) passIdsUsed;

	constructor(address AvaxToUSDAggregatorAddress) NFTManagerBase() {
		dataFeed = AggregatorV3Interface(AvaxToUSDAggregatorAddress);
	}

	function mintNFT(
		address nftCollectionAddress,
		string calldata nftName
	) external payable onlyAuthorizedCollections(nftCollectionAddress) onlyEnoughFundsSent(nftCollectionAddress, msg.value) {
		_mintNFT(nftCollectionAddress, nftName);
	}

	function usdToAvaxToken(uint256 collectionPriceInUSD) public view returns (uint256) {
		uint256 avaxUsd = uint256(getChainlinkDataFeedAvaxToUSD());
		uint256 avaxWeiNeeded = (uint(collectionPriceInUSD) * 10 ** 24) / avaxUsd; //24 18 from wei + 8 from avaxtousd - 2 from the collection price

		return avaxWeiNeeded;
	}

	function setPassUsed(address passAddress, uint passId, bytes32 collectionName) external onlyAuthorizedCollections(passAddress) {
		ICollectionNFT collection = getCollectionContract(passAddress);
		collection.setTrait(passId, Types.Trait(true, Types.TraitType.Text, Constants.PASS_COLLECTION_LABEL, collectionName));
		collection.setTrait(passId, Types.Trait(true, Types.TraitType.Text, Constants.PASS_COLLECTION_ADDRESS_LABEL, bytes32(abi.encodePacked(passAddress))));
	}

	function getCollectionPrice(address nftCollectionAddress) external view onlyAuthorizedCollections(nftCollectionAddress) returns (uint256) {
		return _getCollectionPrice(nftCollectionAddress);
	}

	function _getCollectionPrice(address nftCollectionAddress) internal view returns (uint256 priceInAvaxToken) {
		ICollectionConfig collectionConfig = getCollectionConfigContract(getCollectionContract(nftCollectionAddress));
		(uint256 price, , ) = collectionConfig.getCollectionAttributes();
		if (price > 0) {
			priceInAvaxToken = usdToAvaxToken(price);
			// require(msg.value >= tokenAmount(), "Not enough funds sent!");
		}
	}

	modifier onlyEnoughFundsSent(address nftCollectionAddress, uint256 valueSent) {
		uint256 collectionPriceInAvaxToken = _getCollectionPrice(nftCollectionAddress);
		require(collectionPriceInAvaxToken == 0 || valueSent >= collectionPriceInAvaxToken, "Not enough funds sent!");
		_;
	}

	/**
	 * Returns the latest answer.
	 */
	function getChainlinkDataFeedAvaxToUSD() public view returns (int) {
		(, int answer, , , ) = dataFeed.latestRoundData();
		return answer;
	}

	modifier verifyPassValidity(address nftCollectionAddress, uint tokenId) {
		_;
	}

	function isAuthorized(
		address nftCollectionAddress,
		uint tokenId,
		bytes32 originalMessage,
		bytes memory signature
	) external view onlyAuthorizedCollections(nftCollectionAddress) verifyPassValidity(nftCollectionAddress, tokenId) {
		ICollectionNFT collection = getCollectionContract(nftCollectionAddress);
		if (bytes32(0) != collection.getTraitValue(tokenId, Constants.PASS_COLLECTION_LABEL)) {
			revert("This pass has been used already");
		}
		address passOwner = collection.getOwner(tokenId);
		bool isSignatureVerified = originalMessage.recover(signature) == passOwner;

		require(isSignatureVerified, "The pass is not owned by the sender!");
	}

	function isAuthorizedV2(
		address nftCollectionAddress,
		uint tokenId,
		//string memory originalMessage,
		bytes32 originalMessage,
		bytes memory signature
	) external view onlyAuthorizedCollections(nftCollectionAddress) verifyPassValidity(nftCollectionAddress, tokenId) {
		ICollectionNFT collection = getCollectionContract(nftCollectionAddress);
		address passOwner = collection.getOwner(tokenId);

		// bytes32 hashedMessage = MessageHashUtils.toEthSignedMessageHash(bytes(originalMessage));
		bytes32 hashedMessage = MessageHashUtils.toEthSignedMessageHash(originalMessage);
		bool isSignatureVerified = hashedMessage.recover(signature) == passOwner;

		require(isSignatureVerified, "The pass is not owned by the sender!");
	}
}
