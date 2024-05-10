// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IRandomConsumer.sol";
import "./NFTRandomManager.sol";

abstract contract RandomConsumerBase is IRandomConsumer {
	uint8 constant MAX_RANDOM_WORDS = 10;

	NFTRandomManager private nftRandomManager;

	constructor(address nftRandomManagerAddress) {
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	function requestRandom(address requestor, uint256 tokenId, uint8 numWords) internal {
		require(numWords <= MAX_RANDOM_WORDS, "Cannot request more than 10 words at a time");
		nftRandomManager.requestRandomWords(requestor, tokenId, numWords);
	}
}
