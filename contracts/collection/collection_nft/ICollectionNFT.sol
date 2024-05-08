// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./../collection_config/ICollectionConfig.sol";

interface ICollectionNFT is IAccessControl, IERC721 {
	function getNFTDetails(uint256 tokenId) external view returns (Types.NFT memory, Types.Trait[] memory);

	function setTokenURIBaseURL(string calldata _tokenURIBaseURL) external;

	function getCollectionAddress() external view returns (address);

	/**
	 *
	 * @param to The mint to
	 * @param name The name of the token
	 */
	function safeMint(address to, string calldata name) external;

	/**
	 *
	 * This is the callback from the random manager, which will call VRF and then call this contract to proceed with the mint.
	 * This is only authorized to be called from the random manager contract
	 *
	 * @param tokenId The token id for which a random number was requested
	 * @param genes The random number which represent the genes that will be used to determine the traits that will be given to the new nft
	 */
	function generate(uint tokenId, uint genes) external;

	function getOwner(uint tokenId) external view returns (address);

	function getTraitByKey(uint256 tokenId, bytes32 traitKey) external view returns (Types.Trait memory traitValue);

	function setTrait(uint256 tokenId, bytes32 traitKey, Types.Trait memory trait) external;
}
