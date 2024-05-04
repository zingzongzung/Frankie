// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Deploy this contract on Fuji

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/CollectionGenerator.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract NFTManager is AccessControl, ReentrancyGuard {
	AggregatorV3Interface internal dataFeed;

	address[] managedCollectionGenerators;
	mapping(address => uint8) managedCollectionGeneratorsIndex;

	constructor(address AvaxToUSDAggregatorAddress) {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		dataFeed = AggregatorV3Interface(AvaxToUSDAggregatorAddress);
	}

	function mintNFT(
		address nftCollectionAddress,
		string calldata nftName
	) public payable onlyAuthorizedCollections(nftCollectionAddress) onlyEnoughFundsSent(nftCollectionAddress, msg.value) {
		CollectionGenerator generator = CollectionGenerator(nftCollectionAddress);

		generator.safeMint(msg.sender, nftName);
	}

	function addManagedCollection(address nftCollectionAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
		managedCollectionGenerators.push(nftCollectionAddress);
		managedCollectionGeneratorsIndex[nftCollectionAddress] = 1;
	}

	function getManagedCollections() external view returns (address[] memory) {
		return managedCollectionGenerators;
	}

	function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
		payable(msg.sender).transfer(address(this).balance);
	}

	//Collection price 33.50
	//AVAX Price       33.51772906
	//                  33500000000000000000
	//                  33517729060000000000
	//                  0.000000000000000000
	// 					  999471054260022710
	//                    999471054260000000
	//                    99947105426002
	//                    999471054260022710
	//                    999471054260022710
	//                    98470275062244924059

	function usdToAvaxToken(uint256 collectionPriceInUSD) public view returns (uint256) {
		uint256 avaxUsd = uint256(getChainlinkDataFeedAvaxToUSD());
		uint256 avaxWeiNeeded = (uint(collectionPriceInUSD) * 10 ** 24) / avaxUsd; //24 18 from wei + 8 from avaxtousd - 2 from the collection price

		return avaxWeiNeeded;
	}

	function getCollectionPrice(address nftCollectionAddress) external view onlyAuthorizedCollections(nftCollectionAddress) returns (uint256) {
		return _getCollectionPrice(nftCollectionAddress);
	}

	function _getCollectionPrice(address nftCollectionAddress) internal view returns (uint256 priceInAvaxToken) {
		CollectionGenerator generator = CollectionGenerator(nftCollectionAddress);
		Collection collection = Collection(generator.getCollectionAddress());
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

	modifier onlyAuthorizedCollections(address nftCollectionAddress) {
		require(managedCollectionGeneratorsIndex[nftCollectionAddress] == 1, "This collection is not managed by this");
		_;
	}
}
