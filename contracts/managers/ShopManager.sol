// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "../interfaces/ICollectionGenerator.sol";
import "./NFTManager.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ShopManager is NFTManager {
	AggregatorV3Interface internal dataFeed;

	constructor(address AvaxToUSDAggregatorAddress) NFTManager() {
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
		ICollectionGenerator generator = ICollectionGenerator(nftCollectionAddress);
		ICollection collection = ICollection(generator.getCollectionAddress());
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
}
