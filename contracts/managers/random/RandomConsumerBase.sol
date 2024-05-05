// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IRandomConsumer.sol";
import "./NFTRandomManager.sol";

abstract contract RandomConsumerBase is IRandomConsumer {
	NFTRandomManager private nftRandomManager;

	constructor(address nftRandomManagerAddress) {
		nftRandomManager = NFTRandomManager(nftRandomManagerAddress);
	}

	function requestRandom(address requestor, uint256 tokenId) internal {
		nftRandomManager.requestRandomWords(requestor, tokenId);
	}
}
