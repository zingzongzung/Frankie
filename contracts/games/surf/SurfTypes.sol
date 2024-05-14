// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../collection/collection_nft/ICollectionNFT.sol";

library SurfTypes {
	bytes32 constant SUPER_TUBOS = bytes32("Super Tubos");

	bytes32 constant TAKE_OFF = bytes32("Take off");
	bytes32 constant BOTTOM_TURN = bytes32("Bottom turn");

	bytes32 constant SPEED_UP = bytes32("Speed up");
	bytes32 constant SPEED_DOWN = bytes32("Speed down");
	bytes32 constant CUT_BACK = bytes32("Cut Back");
	bytes32 constant AERIAL = bytes32("Aerial");
	bytes32 constant TUBE = bytes32("Tube");
	bytes32 constant WIPEOUT = bytes32("Wipeout");

	struct SurfAction {
		bytes32 name; //This is used as key as well
		int32 scoreChange;
		int32 speedChange;
	}

	struct SurfWave {
		bytes32 name;
		uint32 waveMaxLength;
		uint32 wavePower; //maybe modifier for some checks
		uint32 waveSpeed;
		WaveSide waveSide; //modifier for some checks
		uint32 waveCapacity;
	}

	enum WaveSide {
		Left,
		Right
	}

	struct RunLog {
		bytes32 actionName;
		int32 currentSpeed;
		int32 currentScore;
	}

	/**
	 * adf
	 */
	struct Surfer {
		address surferAddress;
		uint256 surferId;
		address surfboardAddress;
		uint256 surfboardId;
	}
}
