// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../collection/collection_nft/ICollectionNFT.sol";

library SurfTypes {
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

	bytes32 constant BOARD_SPEED = bytes32("Speed");

	uint256 constant EXPERIENCE_BY_LEVEL_FACTOR = 50;

	struct SurfAction {
		bytes32 name; //This is used as key as well
		int32 speedChange;
		uint scoreChange;
	}

	struct SurfWave {
		uint32 waveMaxLength;
		uint32 wavePower;
		uint32 waveSpeed;
	}

	struct ScoreLog {
		uint surferId;
		uint surfBoardId;
		uint surferScore;
	}

	//Represents the wave ridden, actions taken and final score
	struct RunLog {
		uint timestamp;
		uint surfboardId;
		bytes32 actionName;
		int32 currentSpeed;
		uint currentScore;
	}

	/**
	 * adf
	 */
	struct Surfer {
		uint256 surferId;
		uint256 surfboardId;
	}
}
