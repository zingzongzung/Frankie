// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./../collection_config/ICollectionConfig.sol";
import "../../managers/random/IRandomConsumer.sol";
import "./IERC7496.sol";
import "./../../libraries/Types.sol";

interface ICollectionNFT is IAccessControl, IERC721, IERC7496, IRandomConsumer {
	function getNFTDetails(uint256 tokenId) external view returns (Types.NFT memory, Types.Trait[] memory);

	function setTokenURIBaseURL(string calldata _tokenURIBaseURL) external;

	function getCollectionAddress() external view returns (address);

	/**
	 *
	 * @param to The mint to
	 * @param name The name of the token
	 */
	function safeMint(address to, string calldata name) external;

	function getOwner(uint tokenId) external view returns (address);

	function getTraitByKey(uint256 tokenId, bytes32 traitKey) external view returns (Types.Trait memory traitValue);

	function setTrait(uint256 tokenId, Types.Trait memory trait) external;

	function setTraits(uint256 tokenId, Types.Trait[] memory traits) external;
}
