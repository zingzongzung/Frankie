// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../managers/nfts/NFTManagerBase.sol";
import "../../managers/random/RandomConsumerBase.sol";
import "../../libraries/Roles.sol";
import "../../libraries/NumberUtils.sol";
import "./SurfLib.sol";
import "./SurfQueue.sol";
import "./Functions/SurfForecastServiceConsumer.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./SurfGameScoreManager.sol";
import "./SurfForecastLib.sol";

/**
 *
 * This represents a surf game.
 *
 * Each day the conditions are feteched from a marine forecast external system through the use of chianlink functions.
 * To trigger this request chainlink automation with a daily interval. The conditons affect the wave characteristics
 *
 * VRF is used to get a random seed , which will be used to determine how the surfer surfs the wave
 *
 * Automation is also used to run the game. It is only called when the conditions to run successfully are met
 * The conditions are:
 * 		there aresurfers in the line up
 * 		here are wave seeds.
 *
 * @title Surf Game
 * @author
 * @notice
 */
contract SurfGame is NFTManagerBase, RandomConsumerBase, SurfQueue, SurfForecastServiceConsumer, AutomationCompatibleInterface, SurfGameScoreManager {
	//Events
	event SurferAddedToQueue();
	event WaveSurfEnd();
	event WaveConditionsSet();
	event RequestingWaveSeed();

	//see https://docs.chain.link/chainlink-automation/guides/forwarder
	address private runGameForwarder;
	address private performWaveUpdateForwarder;

	//Managed Collection
	address private surferCollectionAddress;
	address private surfboardCollectionAddress;

	//Populated from functions
	SurfTypes.SurfWave private currentWave;

	//Populated randomly by VRF
	uint256[] private waveSeeds;
	bool isRequestingWaveSeeds;

	//add a way to get the last surfer log
	mapping(address => mapping(uint256 => mapping(uint256 => SurfTypes.RunLog[]))) private surferLogs;
	mapping(address => mapping(uint256 => uint256)) private surferRunsLength;
	mapping(address => mapping(uint256 => uint256)) private surferQueuePosition;
	mapping(address => mapping(uint256 => uint256)) private surfboardQueuePosition;

	constructor(
		address randomManager,
		address surfForecastServiceAddress
	) NFTManagerBase() RandomConsumerBase(randomManager) SurfForecastServiceConsumer(surfForecastServiceAddress) {
		setTimestamp();
		treshold = 60;
	}

	function setSurfGameAddresses(address _surferCollectionAddress, address _surfboardCollectionAddress) external {
		require(surferCollectionAddress == address(0) && surfboardCollectionAddress == address(0), "The addresses are already set");
		surferCollectionAddress = _surferCollectionAddress;
		surfboardCollectionAddress = _surfboardCollectionAddress;
		addManagedCollection(_surferCollectionAddress);
		addManagedCollection(_surfboardCollectionAddress);
	}

	function getGameAddresses() external view returns (address _surferCollectionAddress, address _surfboardCollectionAddress) {
		_surferCollectionAddress = surferCollectionAddress;
		_surfboardCollectionAddress = surfboardCollectionAddress;
	}

	/**
	 *
	 * surfer manipulation logic
	 *
	 **/
	function getSurferRunLog(address surferAddress, uint256 tokenId, uint256 surferRunId) external view onlyAuthorizedCollections(surferAddress) returns (SurfTypes.RunLog[] memory) {
		return surferLogs[surferAddress][tokenId][surferRunId];
	}

	function getSurferRuns(address surferAddress, uint256 surferId) external view returns (uint256) {
		return surferRunsLength[surferAddress][surferId];
	}

	function getSurferQueuePosition(address surferAddress, uint256 tokenId) external view returns (uint256) {
		return surferQueuePosition[surferAddress][tokenId];
	}

	function getSurfboardQueuePosition(address surfboardAddress, uint256 tokenId) external view returns (uint256) {
		return surfboardQueuePosition[surfboardAddress][tokenId];
	}

	function queueStatus(uint numberOfResults) external view returns (SurfTypes.Surfer[] memory result) {
		uint256 resultIndex;
		numberOfResults = numberOfResults > getQueueLength() ? getQueueLength() : numberOfResults;
		result = new SurfTypes.Surfer[](numberOfResults);
		for (uint queueIndex = getQueueFront(); queueIndex <= getQueueBack(); queueIndex++) {
			result[resultIndex] = getSurferAtPosition(queueIndex);
			resultIndex++;
			if (resultIndex == numberOfResults) {
				break;
			}
		}
	}

	function addSurferToQueue(
		address surferAddress,
		uint256 surferId,
		address surfBoardAddress,
		uint256 surfboardId
	)
		external
		onlyAuthorizedCollections(surferAddress)
		onlyAuthorizedCollections(surfBoardAddress)
		onlyNFTOwner(surferAddress, surferId)
		onlyNFTOwner(surfBoardAddress, surfboardId)
	{
		require(surferAddress != surfBoardAddress, "Surfer address is the same as the surfboard address provided");
		require(surferQueuePosition[surferAddress][surferId] == 0, "Surfer is already queued");
		require(surfboardQueuePosition[surfBoardAddress][surfboardId] == 0, "Surfboard is already queued");
		addToSurfQueue(SurfTypes.Surfer(surferId, surfboardId));
		surferQueuePosition[surferAddress][surferId] = getQueueBack();
		surfboardQueuePosition[surfBoardAddress][surfboardId] = getQueueBack();
		requestWaveSeedsIfNeeded();
		emit SurferAddedToQueue();
	}

	/**
	 *
	 * Gamne engine logic
	 *
	 **/
	function canRun() internal view returns (bool) {
		return !isSurfQueueEmpty() && !isRequestingWaveSeeds;
	}

	function runGame() internal {
		if (!requestWaveSeedsIfNeeded() && canRun()) {
			uint256 waveSeed = getAvailableWaveSeed();

			SurfTypes.Surfer memory surfer = getFromSurfQueue();
			doRun(waveSeed, surfer);
			surferRunsLength[surferCollectionAddress][surfer.surferId]++;
			delete surferQueuePosition[surferCollectionAddress][surfer.surferId];
			delete surfboardQueuePosition[surfboardCollectionAddress][surfer.surfboardId];

			emit WaveSurfEnd();
		} else {
			emit RequestingWaveSeed();
		}
	}

	/**
	 *
	 * Generates a random run log based on a seed
	 *
	 * @param waveSeed the wave seed, a uint256 that represents the randomness of this run
	 */
	function doRun(uint256 waveSeed, SurfTypes.Surfer memory surfer) internal {
		uint8 waveSeedLength = NumberUtils.countDigits(waveSeed);
		uint8 currentRunSpecIndex = 0;
		uint32 waveSections = 0;
		uint32 actionProbability = 0;
		uint32 randomStartFactor = 0;
		int32 currentSpeed = int32(uint32(SurfLib.getBoardSpeed(surfboardCollectionAddress, surfer.surfboardId)));
		uint currentScore = 0;
		bool isWipeout;
		bool isShark;

		//Calculates total wave sections based on the random + the wave configuration
		(waveSections, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 2, waveSeedLength);
		waveSections = currentWave.waveMaxLength - (waveSections % currentWave.waveMaxLength);

		//Sets the basic actions every wave will ahve
		(randomStartFactor, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 1, waveSeedLength);
		(currentSpeed, currentScore) = logAction(surfer, SurfTypes.SurfAction(SurfTypes.TAKE_OFF, int32(randomStartFactor), randomStartFactor), currentSpeed, currentScore);

		(randomStartFactor, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 1, waveSeedLength);
		(currentSpeed, currentScore) = logAction(surfer, SurfTypes.SurfAction(SurfTypes.BOTTOM_TURN, int32(randomStartFactor), randomStartFactor), currentSpeed, currentScore);

		//Random actions
		//2 is the number of fixed actions
		for (uint8 waveSection = 2; waveSection < waveSections + 2; waveSection++) {
			(actionProbability, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 2, waveSeedLength);
			(currentSpeed, currentScore, isWipeout, isShark) = logRandomAction(surfer, actionProbability, currentSpeed, currentScore);

			if (currentSpeed < int32(currentWave.waveSpeed)) {
				isWipeout = true;
				logAction(surfer, SurfTypes.SurfAction(SurfTypes.LOST_SPEED, 0, 0), currentSpeed, currentScore);
				break;
			}
			if (isWipeout) {
				break;
			}
		}

		if (!isWipeout) logAction(surfer, SurfTypes.SurfAction(SurfTypes.END, 0, 0), currentSpeed, currentScore);

		//Apply multiplier to score
		addScore(surferCollectionAddress, surfer.surferId, surfer.surfboardId, isShark ? currentScore : currentScore * currentWave.wavePower);
		increaseLevel(surfer, currentScore);
	}

	function logRandomAction(
		SurfTypes.Surfer memory surfer,
		uint32 actionProbability,
		int32 currentSpeed,
		uint currentScore
	) internal returns (int32 newSpeed, uint newScore, bool isWipeout, bool isShark) {
		SurfTypes.SurfAction memory currentAction = SurfLib.getActionByProbability(actionProbability, surferCollectionAddress, surfer.surferId);
		(newSpeed, newScore) = logAction(surfer, currentAction, currentSpeed, currentScore);
		isShark = currentAction.name == SurfTypes.SHARK;
		isWipeout = currentAction.name == SurfTypes.WIPEOUT || isShark;
	}

	function logAction(
		SurfTypes.Surfer memory surfer,
		SurfTypes.SurfAction memory currentAction,
		int32 currentSpeed,
		uint currentScore
	) internal returns (int32 newSpeed, uint newScore) {
		(newSpeed, newScore) = SurfLib.processAction(currentAction, currentSpeed, currentScore, 0, 0);
		surferLogs[surferCollectionAddress][surfer.surferId][surferRunsLength[surferCollectionAddress][surfer.surferId]].push(
			SurfTypes.RunLog(block.timestamp, surfer.surfboardId, currentAction.name, newSpeed, newScore)
		);
	}

	/**
	 *
	 * Updates the traits of the surfer
	 *
	 * @param surfer The surfer to update
	 * @param score The score obtained that will determine experience gained
	 */
	function increaseLevel(SurfTypes.Surfer memory surfer, uint score) internal {
		ICollectionNFT surferContract = ICollectionNFT(surferCollectionAddress);
		(uint currentLevel, uint currentExperience) = SurfLib.getSurferTraits(surferContract, surfer);

		uint256 totalExperience = currentExperience + score;

		uint256 newLevel = SurfLib.calculateLevel(currentLevel, totalExperience);
		if (newLevel > currentLevel) {
			surferContract.setTrait(surfer.surferId, Types.Trait(true, Types.TraitType.Number, SurfTypes.SURF_LEVEL, bytes32(newLevel)));
		}
		surferContract.setTrait(surfer.surferId, Types.Trait(true, Types.TraitType.Number, SurfTypes.SURF_EXPERIENCE, bytes32(totalExperience)));
	}

	/**
	 *
	 * Waves logic
	 *
	 */
	function addWaveSeed(uint waveSeed) internal {
		waveSeeds.push(waveSeed);
	}

	function peekWaveSeed() external view returns (uint256 waveSeed) {
		return waveSeeds.length > 0 ? waveSeeds[waveSeeds.length - 1] : 0;
	}

	function getAvailableWaveSeed() internal returns (uint256 waveSeed) {
		waveSeed = waveSeeds[waveSeeds.length - 1];
		waveSeeds.pop();
	}

	function handleVRFResponse(uint /* tokenId */, uint[] memory randomWords) external override {
		for (uint256 currentIndex; currentIndex < randomWords.length; currentIndex++) {
			addWaveSeed(randomWords[currentIndex]);
		}
		isRequestingWaveSeeds = false;
	}

	function requestWaveSeedsIfNeeded() internal returns (bool requested) {
		if (waveSeeds.length == 0) {
			requestRandom(address(this), 0, MAX_RANDOM_WORDS);
			requested = true;
			isRequestingWaveSeeds = true;
		}
	}

	function handleForecastServiceResponse(bytes32 /*requestId*/, bytes memory response) external override {
		/* shouuld use request id to verify */
		setWaveConditions(response);
		emit WaveConditionsSet();
	}

	/**
	 * Set wave will be set daily by the integration with Weather Forecast API
	 */
	function setWaveConditions(bytes memory response) internal {
		currentWave = SurfForecastLib.surfForecastServiceResponseToSurfWave(response);
	}

	function getCurrentWaveConditions() external view returns (SurfTypes.SurfWave memory) {
		return currentWave;
	}

	/**
	 *
	 * Modifier to check if wallet holds the nft
	 */
	modifier onlyNFTOwner(address collectionNFTaddress, uint256 tokenId) {
		ICollectionNFT collectionNFT = ICollectionNFT(collectionNFTaddress);
		if (msg.sender != collectionNFT.getOwner(tokenId)) {
			revert("Not owner of the NFT");
		}
		_;
	}

	/**
	 *
	 * Automation
	 *
	 */
	function setRunGameForwarderAddress(address forwarderAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
		runGameForwarder = forwarderAddress;
	}

	function getRunGameForwarderAddress() external view returns (address) {
		return runGameForwarder;
	}

	function setWaveUpdateForwarderAddress(address forwarderAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
		performWaveUpdateForwarder = forwarderAddress;
	}

	/**
	 * Calls forecast service (through functions) to get the configuration of a new wave
	 * Should be called periodically by the automation service
	 */
	// State variable to store the initial timestamp
	uint256 private initialTimestamp;
	uint256 private treshold;

	// Function to set the initial timestamp
	function setTimestamp() internal {
		initialTimestamp = block.timestamp;
	}

	function setTreshold(uint256 _treshold) external {
		treshold = _treshold;
	}

	// Function to check if treshold seconds have passed since the initial timestamp
	function hasTresholdPassed() internal view returns (bool) {
		if (block.timestamp >= initialTimestamp + treshold) {
			return true;
		} else {
			return false;
		}
	}

	function sendRequest() public override returns (bytes32 requestId) {
		require(performWaveUpdateForwarder == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You have no permissions to invoke this function");
		return surfForecastService.sendRequest(address(this));
	}

	function withdraw() external override onlyRole(DEFAULT_ADMIN_ROLE) {}

	function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
		upkeepNeeded = hasTresholdPassed() && canRun();
	}

	function performUpkeep(bytes calldata /* performData */) external override {
		require(runGameForwarder == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "You have no permissions to invoke this function");
		runGame();
		setTimestamp();
	}
}
