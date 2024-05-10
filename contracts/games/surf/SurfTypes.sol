// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library SurfTypes {
	struct SurfAction {
		bytes32 name; //This is used as key as well
		uint256 baseScore;
	}

	struct SurfWave {
		bytes32 name;
		uint8 waveMaxLength;
		uint8 wavePower;
		uint8 waveSpeed;
		WaveSide waveSide;
	}

	enum WaveSide {
		Left,
		Right
	}

	struct RunLog {
		uint8 currentSpeed;
		SurfAction action;
		uint currentScore;
		uint totalScore;
	}

	//Traits
	enum TraitType {
		Options,
		Number,
		OptionsWithImage,
		Text
	}
}
