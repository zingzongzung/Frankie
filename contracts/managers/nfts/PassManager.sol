// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "./NFTManagerBase.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "../../libraries/SignatureVerifier.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract PassManager is NFTManagerBase {
	AggregatorV3Interface internal dataFeed;

	constructor(address AvaxToUSDAggregatorAddress) NFTManagerBase() {
		dataFeed = AggregatorV3Interface(AvaxToUSDAggregatorAddress);
	}

	function mintNFT(
		address nftCollectionAddress,
		string calldata nftName
	) public payable onlyAuthorizedCollections(nftCollectionAddress) onlyEnoughFundsSent(nftCollectionAddress, msg.value) {
		_mintNFT(nftCollectionAddress, nftName);
	}

	function usdToAvaxToken(uint256 collectionPriceInUSD) public view returns (uint256) {
		uint256 avaxUsd = uint256(getChainlinkDataFeedAvaxToUSD());
		uint256 avaxWeiNeeded = (uint(collectionPriceInUSD) * 10 ** 24) / avaxUsd; //24 18 from wei + 8 from avaxtousd - 2 from the collection price

		return avaxWeiNeeded;
	}

	function getCollectionPrice(address nftCollectionAddress) external view onlyAuthorizedCollections(nftCollectionAddress) returns (uint256) {
		return _getCollectionPrice(nftCollectionAddress);
	}

	function _getCollectionPrice(address nftCollectionAddress) internal view returns (uint256 priceInAvaxToken) {
		(ICollectionConfig collection, ) = getCollection(nftCollectionAddress);
		(uint256 price, , ) = collection.getCollectionAttributes();
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

	function teste(address passNFTAddress, uint tokenId) external view returns (address) {
		(, ICollectionNFT generator) = getCollection(passNFTAddress);
		address passOwner = generator.getOwner(tokenId);

		return passOwner;
	}

	function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
		/*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
	}

	function testeGetSigner(string memory originalMessage, bytes memory signature) external pure returns (address) {
		(address signer, ECDSA.RecoverError err, ) = ECDSA.tryRecover(MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encodePacked(originalMessage))), signature);

		return signer;
	}

	function isAuthorized(address passNFTAddress, uint tokenId, bytes32 originalMessage, bytes memory signature) external view {
		(, ICollectionNFT generator) = getCollection(passNFTAddress);
		address passOwner = generator.getOwner(tokenId);
		bool isSignatureVerified = true; //SignatureVerification.verifySignature(passOwner, originalMessage, signature);

		require(isSignatureVerified, "This nft is not owned by the sender!");
	}
}
