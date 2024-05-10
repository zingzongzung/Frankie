// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../managers/nfts/NFTManagerBase.sol";
import "../../managers/random/RandomConsumerBase.sol";
import "../../libraries/Roles.sol";
import "../../libraries/NumberUtils.sol";
import "hardhat/console.sol";

contract SurfGame is NFTManagerBase, RandomConsumerBase {
	SurfTypes.SurfWave currentWave;

	SurfTypes.RunLog[] waveLog;

	mapping(address => ICollectionNFT) surfboardCollections;
	mapping(address => ICollectionNFT) surferCollections;

	uint8[] actionChances;
	mapping(uint8 => SurfTypes.SurfAction) actionDistribution;

	uint256 currentLog;
	mapping(uint256 => SurfTypes.RunLog[]) runLogs;

	uint256[] waveSeeds;

	bool needsMoreWaves;

	uint head;
	uint surferQueueLength;
	mapping(uint => ICollectionNFT) surferQueue;

	constructor(address randomManager) NFTManagerBase() RandomConsumerBase(randomManager) {
		setWave();
		setActionDistribution();
	}

	function addSurfCollection(address surfCollectionAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
		surfboardCollections[surfCollectionAddress] = ICollectionNFT(surfCollectionAddress);
		addManagedCollection(surfCollectionAddress);
	}

	function addSurferCollection(address surferCollectionAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
		surfboardCollections[surferCollectionAddress] = ICollectionNFT(surferCollectionAddress);
		addManagedCollection(surferCollectionAddress);
	}

	function setActionDistribution() internal {
		actionChances = [20, 20, 10, 10, 10, 30];
		//for (uint8 actionIndex = 0 ; actionIndex < actionChances.length ; actionIndex++) {}
		actionDistribution[0] = SurfTypes.SurfAction(SurfTypes.SPEED_UP, 5, 5);
		actionDistribution[1] = SurfTypes.SurfAction(SurfTypes.SPEED_DOWN, 1, -5);
		actionDistribution[2] = SurfTypes.SurfAction(SurfTypes.CUT_BACK, 8, -4);
		actionDistribution[3] = SurfTypes.SurfAction(SurfTypes.AERIAL, 9, -10);
		actionDistribution[4] = SurfTypes.SurfAction(SurfTypes.TUBE, 10, -20);
		actionDistribution[5] = SurfTypes.SurfAction(SurfTypes.WIPEOUT, 0, 0);
	}

	function addWaveSeed(uint waveSeed) internal {
		waveSeeds.push(waveSeed);
	}

	function getAvailableWaveSeed() internal returns (uint256 waveSeed) {
		if (waveSeeds.length == 0) {
			needsMoreWaves = true;
		}
		waveSeed = waveSeeds[waveSeeds.length - 1];
		waveSeeds.pop();
	}

	function setWave() internal {
		currentWave = SurfTypes.SurfWave(SurfTypes.SUPER_TUBOS, 55 /* waveMaxLength */, 50 /* power */, 30 /* speed */, SurfTypes.WaveSide.Left);
	}

	function getActionByProbability(uint32 probability) internal view returns (SurfTypes.SurfAction memory surfAction) {
		uint8 actionIndex = 0;
		uint8 probabilityStart = 0;
		uint8 probabilityEnd = 0;
		for (uint8 currentProbability = 0; currentProbability < actionChances.length; currentProbability++) {
			probabilityEnd += actionChances[currentProbability];
			if (probability > probabilityStart && probability <= probabilityEnd) {
				actionIndex = currentProbability;
				break;
			}
			probabilityStart = probabilityEnd;
		}
		surfAction = actionDistribution[actionIndex];
	}

	function processAction(
		SurfTypes.SurfAction memory currentAction,
		int32 currentSpeed,
		int32 currentScore,
		int32 speedModifier,
		int32 scoreModifier
	) internal pure returns (int32 newSpeed, int32 newScore) {
		newSpeed = currentSpeed + currentAction.speedChange + speedModifier;
		newScore = currentScore + currentAction.scoreChange + scoreModifier;
	}

	function getRun(uint logId) external view returns (SurfTypes.RunLog[] memory runLog) {
		return runLogs[logId];
	}

	function doRun(uint waveSeed) external {
		uint8 treshold = NumberUtils.countDigits(waveSeed);
		uint8 currentRunSpecIndex = 0;
		uint32 waveSections = 0;
		uint32 actionProbability = 0;
		int32 currentSpeed = 100; //maybe influenced by the board and the surfer
		int32 currentScore = 0;
		SurfTypes.SurfAction memory currentAction;

		(waveSections, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 2, treshold);
		waveSections = currentWave.waveMaxLength - (currentWave.waveMaxLength % waveSections);

		currentAction = SurfTypes.SurfAction(SurfTypes.TAKE_OFF, 5, 0);
		(currentSpeed, currentScore) = processAction(currentAction, currentSpeed, currentScore, 0, 0);
		runLogs[currentLog].push(SurfTypes.RunLog(currentAction.name, currentSpeed, currentScore));

		currentAction = SurfTypes.SurfAction(SurfTypes.BOTTOM_TURN, 5, 0);
		(currentSpeed, currentScore) = processAction(currentAction, currentSpeed, currentScore, 0, 0);
		runLogs[currentLog].push(SurfTypes.RunLog(currentAction.name, currentSpeed, currentScore));

		//Random actions
		//2 is the number of fixed actions
		for (uint8 waveSection = 2; waveSection < waveSections + 2; waveSection++) {
			(actionProbability, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 2, treshold);
			currentAction = getActionByProbability(actionProbability);
			(currentSpeed, currentScore) = processAction(currentAction, currentSpeed, currentScore, 0, 0);
			runLogs[currentLog].push(SurfTypes.RunLog(currentAction.name, currentSpeed, currentScore));
			if (currentAction.name == SurfTypes.WIPEOUT) {
				//Just Wipeout
				break;
			} else if (currentSpeed < int32(currentWave.waveSpeed)) {
				//Speed Wipeout
				runLogs[currentLog].push(SurfTypes.RunLog(SurfTypes.WIPEOUT, 0, currentScore));
				break;
			}
		}

		currentLog++;
	}

	function generate(uint tokenId, uint[] memory randomWords) external override {}
}

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
}

contract Queue {
	mapping(uint256 => uint256) private queue;
	uint256 private front = 1;
	uint256 private back = 0;

	function add(uint256 data) public {
		back++;
		queue[back] = data;
	}

	function get() public returns (uint256) {
		require(front <= back, "Queue is empty");

		uint256 data = queue[front];
		delete queue[front];

		if (isEmpty()) {}
		front++;
		return data;
	}

	function isEmpty() public view returns (bool) {
		return front > back;
	}

	function reset() internal {
		front = 1;
		back = 0;
	}
}
