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
	bytes32 constant END = bytes32("Wave End");
	bytes32 constant LOST_SPEED = bytes32("No Speed");
	bytes32 constant WIPEOUT = bytes32("Wipeout");
	bytes32 constant SHARK = bytes32("Shark");

	//Surfer Management
	bytes32 constant SURF_LEVEL = bytes32("Surf Level");
	bytes32 constant SURF_EXPERIENCE = bytes32("Surf Experience");

	uint256 constant EXPERIENCE_BY_LEVEL_FACTOR = 50;

	struct SurfAction {
		bytes32 name; //This is used as key as well
		int32 speedChange;
		uint scoreChange;
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

	struct ScoreLog {
		address surferAddress;
		uint surferId;
		uint surferScore;
	}

	//Represents the wave ridden, actions taken and final score
	struct RunLog {
		uint timestamp;
		bytes32 actionName;
		int32 currentSpeed;
		uint currentScore;
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
