// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/Types.sol";

interface INFTManager {
	function addManagedCollection(address nftCollectionAddress) external;

	function getManagedCollections() external view returns (address[] memory);

	function withdraw() external;
}
