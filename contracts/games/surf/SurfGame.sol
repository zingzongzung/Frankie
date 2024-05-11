// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../managers/nfts/NFTManagerBase.sol";
import "../../managers/random/RandomConsumerBase.sol";
import "../../libraries/Roles.sol";
import "../../libraries/NumberUtils.sol";
import "./SurfTypes.sol";
import "./SurferQueue.sol";
import "hardhat/console.sol";

contract SurfGame is NFTManagerBase, RandomConsumerBase, SurferQueue {
	SurfTypes.SurfWave currentWave;
	SurfTypes.RunLog[] waveLog;

	mapping(address => ICollectionNFT) surfboardCollections;
	mapping(address => ICollectionNFT) surferCollections;

	uint8[] actionChances;
	mapping(uint8 => SurfTypes.SurfAction) actionDistribution;

	// uint256 currentLog;
	// mapping(uint256 => SurfTypes.RunLog[]) runLogs;

	uint256[] waveSeeds;

	mapping(address => mapping(uint256 => SurfTypes.RunLog[])) surferLogs;

	constructor(address randomManager) NFTManagerBase() RandomConsumerBase(randomManager) {
		setWave();
		setActionDistribution();
	}

	//Permission and configuration functions
	function addSurfCollection(address surfCollectionAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
		surfboardCollections[surfCollectionAddress] = ICollectionNFT(surfCollectionAddress);
		addManagedCollection(surfCollectionAddress);
	}

	function addSurferCollection(address surferCollectionAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
		surfboardCollections[surferCollectionAddress] = ICollectionNFT(surferCollectionAddress);
		addManagedCollection(surferCollectionAddress);
	}

	function getSurferLogs(address surferAddress, uint256 tokenId) external view onlyAuthorizedCollections(surferAddress) returns (SurfTypes.RunLog[] memory) {
		return surferLogs[surferAddress][tokenId];
	}

	/**
	 * Set wave will be set daily by the integration with Weather Forecast API
	 */
	function setWave() internal {
		currentWave = SurfTypes.SurfWave(SurfTypes.SUPER_TUBOS, 55 /* waveMaxLength */, 50 /* power */, 30 /* speed */, SurfTypes.WaveSide.Left, 2 /* wave capacity */);
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

	function canRun() internal view returns (bool) {
		return waveSeeds.length > 0 && !isSurfQueueEmpty();
	}

	function runGame() external {
		if (canRun()) {
			uint256 waveSeed = getAvailableWaveSeed();
			uint256 queueProcessLength = getQueueLength() > currentWave.waveCapacity ? currentWave.waveCapacity : getQueueLength();
			while (queueProcessLength > 0) {
				SurfTypes.Surfer memory surfer = getFromSurfQueue();
				console.log(surfer.surferId);
				doRun(waveSeed, surfer.surferAddress, surfer.surferId);
				queueProcessLength--;
			}
			//Check if needs more waves
			if (!isSurfQueueEmpty()) {
				requestWaveSeedsIfNeeded();
			}
		} else {
			console.log("didnt run");
		}
	}

	function addSurferToQueue(
		address surferAddress,
		uint256 surferId,
		address surfBoardAddress,
		uint256 surfboardId
	) external onlyAuthorizedCollections(surferAddress) onlyAuthorizedCollections(surfBoardAddress) {
		ICollectionNFT surferNFT = ICollectionNFT(surferAddress);
		ICollectionNFT surfBoard = ICollectionNFT(surfBoardAddress);
		if (msg.sender != surferNFT.getOwner(surferId) || msg.sender != surfBoard.getOwner(surfboardId)) {
			revert("Not owner of these nfts");
		}
		addToSurfQueue(SurfTypes.Surfer(surferAddress, surferId, surfBoardAddress, surfboardId));
		requestWaveSeedsIfNeeded();
	}

	function addWaveSeed(uint waveSeed) internal {
		waveSeeds.push(waveSeed);
	}

	function getAvailableWaveSeed() internal returns (uint256 waveSeed) {
		waveSeed = waveSeeds[waveSeeds.length - 1];
		waveSeeds.pop();
	}

	function getRun(uint logId) external view returns (SurfTypes.RunLog[] memory runLog) {
		//return runLogs[logId];
	}

	/**
	 *
	 * Generates a random run log based on a seed
	 *
	 * @param waveSeed the wave seed, a uint256 that represents the randomness of this run
	 */
	function doRun(uint256 waveSeed, address surferCollectionAddress, uint256 surferId) public {
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
		surferLogs[surferCollectionAddress][surferId].push(SurfTypes.RunLog(currentAction.name, currentSpeed, currentScore));

		currentAction = SurfTypes.SurfAction(SurfTypes.BOTTOM_TURN, 5, 0);
		(currentSpeed, currentScore) = processAction(currentAction, currentSpeed, currentScore, 0, 0);
		surferLogs[surferCollectionAddress][surferId].push(SurfTypes.RunLog(currentAction.name, currentSpeed, currentScore));

		//Random actions
		//2 is the number of fixed actions
		for (uint8 waveSection = 2; waveSection < waveSections + 2; waveSection++) {
			(actionProbability, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 2, treshold);
			currentAction = getActionByProbability(actionProbability);
			(currentSpeed, currentScore) = processAction(currentAction, currentSpeed, currentScore, 0, 0);
			surferLogs[surferCollectionAddress][surferId].push(SurfTypes.RunLog(currentAction.name, currentSpeed, currentScore));
			if (currentAction.name == SurfTypes.WIPEOUT) {
				//Just Wipeout
				break;
			} else if (currentSpeed < int32(currentWave.waveSpeed)) {
				//Speed Wipeout
				surferLogs[surferCollectionAddress][surferId].push(SurfTypes.RunLog(SurfTypes.WIPEOUT, 0, currentScore));
				break;
			}
		}
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

	/**
	 *
	 * VRF integration through random manager
	 *
	 **/

	function handleVRFResponse(uint /* tokenId */, uint[] memory randomWords) external override {
		for (uint256 currentIndex; currentIndex < randomWords.length; currentIndex++) {
			addWaveSeed(randomWords[currentIndex]);
		}
	}

	function requestWaveSeedsIfNeeded() internal {
		if (waveSeeds.length == 0) {
			requestRandom(address(this), 0, MAX_RANDOM_WORDS);
		}
	}
}
