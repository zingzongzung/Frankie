// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "./NFTManagerBase.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ShopManager is NFTManagerBase {
	mapping(address => uint) private mintTotalValue;
	uint private totalTaxes;

	AggregatorV3Interface internal dataFeed;

	constructor(address AvaxToUSDAggregatorAddress) NFTManagerBase() {
		dataFeed = AggregatorV3Interface(AvaxToUSDAggregatorAddress);
	}

	function mintNFT(
		address nftCollectionAddress,
		string calldata nftName
	) external payable onlyAuthorizedCollections(nftCollectionAddress) onlyEnoughFundsSent(nftCollectionAddress, msg.value) {
		_mintNFT(nftCollectionAddress, nftName);
		if (msg.value > 0) {
			splitPayment(nftCollectionAddress, msg.value);
		}
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

	function withdraw() external override onlyRole(DEFAULT_ADMIN_ROLE) {
		require(totalTaxes > 0, "There are no taxes to be whitdrawn");
		payable(msg.sender).transfer(totalTaxes);
		totalTaxes = 0;
	}

	function splitPayment(address nftCollectionAddress, uint paymentValue) internal {
		require(paymentValue > 0, "Value must be greater than zero");
		address collectionOwner = ICollectionNFT(nftCollectionAddress).getCollectionOwner();
		require(collectionOwner != address(0), "Collection owner is not defined");

		// Calculate the 1% fee and the 99% remainder
		uint256 fee = msg.value / 100; // 1% fee
		uint256 remainder = msg.value - fee; // 99% remainder

		totalTaxes += fee;

		// Transfer the remainder to the recipient
		(bool sentRemainder, ) = collectionOwner.call{value: remainder}("");
		require(sentRemainder, "Failed to send remainder");
		mintTotalValue[nftCollectionAddress] += remainder;
	}

	function getMintTotalValuePaid(address nftCollectionAddress) external view returns (uint) {
		return mintTotalValue[nftCollectionAddress];
	}
}
