// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../libraries/Types.sol";

interface INFTManager {
	function addManagedCollection(address nftCollectionAddress) external;

	function isCollectionManaged(address nftCollectionAddress) external view returns (bool);

	function withdraw() external;
}
