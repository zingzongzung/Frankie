// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../managers/nfts/NFTManagerBase.sol";
import "../../managers/random/RandomConsumerBase.sol";
import "../../libraries/Roles.sol";
import "../../libraries/NumberUtils.sol";
import "./SurfTypes.sol";
import "./SurfQueue.sol";
import "hardhat/console.sol";
import "./Functions/SurfForecastServiceConsumer.sol";
import "../../libraries/BytesToValue.sol";

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
contract SurfGame is NFTManagerBase, RandomConsumerBase, SurfQueue, SurfForecastServiceConsumer {
	using BytesToValue for bytes;

	//Events
	event SurferAddedToQueue();
	event WaveSurfEnd();
	event WaveConditionsSet();

	//see https://docs.chain.link/chainlink-automation/guides/forwarder
	address runGameForwarder;
	address performWaveUpdateForwarder;

	//Managed Collection
	address surferCollectionAddress;
	address surfboardCollectionAddress;

	//Populated from functions
	SurfTypes.SurfWave currentWave;

	//Populated randomly by VRF
	uint256[] waveSeeds;

	//add a way to get the last surfer log
	mapping(address => mapping(uint256 => mapping(uint256 => SurfTypes.RunLog[]))) surferLogs;
	mapping(address => mapping(uint256 => uint256)) surferRunsLength;
	mapping(address => mapping(uint256 => uint256)) surferQueuePosition;
	mapping(address => mapping(uint256 => uint256)) surfboardQueuePosition;

	//HiScores
	uint currentRound;
	//This will hold the information about how many participants are in a given round, useful for querying
	mapping(uint => uint) roundPlayers;

	//This indexes the logs of an address + token id (a player ) + the round, so that when we add
	//we can go directly to the round score of this address and overwrite the round score there
	mapping(uint => mapping(address => mapping(uint => uint))) playerRoundIndex;

	//Based on the current round + surfer index we will have  a score that should be manipulated
	mapping(uint => mapping(uint => SurfTypes.ScoreLog)) roundScores;

	constructor(
		address randomManager,
		address surfForecastServiceAddress
	) NFTManagerBase() RandomConsumerBase(randomManager) SurfForecastServiceConsumer(surfForecastServiceAddress) {}

	function setSurfGameAddresses(address _surferCollectionAddress, address _surfboardCollectionAddress) external {
		//This is commented out for develop
		//require(surferCollectionAddress == address(0) && _surfboardCollectionAddress == address(0), "The addresses are already set");
		surferCollectionAddress = _surferCollectionAddress;
		surfboardCollectionAddress = _surfboardCollectionAddress;
		addManagedCollection(_surferCollectionAddress);
		addManagedCollection(_surfboardCollectionAddress);
	}

	function getGameAddresses() external view returns (address _surferCollectionAddress, address _surfboardCollectionAddress) {
		_surferCollectionAddress = surferCollectionAddress;
		_surfboardCollectionAddress = surfboardCollectionAddress;
	}

	/***
	 * Scores Handling
	 */

	function startNewRound() external {
		currentRound += 1;
	}

	function addScore(address surferAddress, uint surferId, uint surferScore) internal {
		uint playerIndex = playerRoundIndex[currentRound][surferAddress][surferId];
		uint playerCurrentScore = roundScores[currentRound][playerIndex].surferScore;
		if (playerCurrentScore == 0) {
			//If player score is 0 , it means it is a new score entry
			roundPlayers[currentRound] += 1;
			playerIndex = roundPlayers[currentRound];
			playerRoundIndex[currentRound][surferAddress][surferId] = playerIndex;
		} else {
			playerCurrentScore = roundScores[currentRound][playerIndex].surferScore;
		}
		roundScores[currentRound][playerIndex] = SurfTypes.ScoreLog(surferAddress, surferId, surferScore + playerCurrentScore);
	}

	function getScore(uint roundIndex, uint playerIndex) public view returns (SurfTypes.ScoreLog memory) {
		return roundScores[roundIndex][playerIndex];
	}

	function getRoundScore(uint roundIndex) public view returns (SurfTypes.ScoreLog[] memory _roundScores) {
		uint roundTotalPlayers = roundPlayers[roundIndex];
		_roundScores = new SurfTypes.ScoreLog[](roundTotalPlayers);
		for (uint playerIndex = 0; playerIndex < roundTotalPlayers; playerIndex++) {
			_roundScores[playerIndex] = getScore(roundIndex, playerIndex + 1);
		}
	}

	/**
	 *
	 * surfer manipulation logic
	 *
	 **/
	function getSurferRunLog(address surferAddress, uint256 tokenId, uint256 surferRunId) public view onlyAuthorizedCollections(surferAddress) returns (SurfTypes.RunLog[] memory) {
		return surferLogs[surferAddress][tokenId][surferRunId];
	}

	function getSurferRunHistory() external view {}

	function getSurferRuns(address surferAddress, uint256 surferId) public view returns (uint256) {
		return surferRunsLength[surferAddress][surferId];
	}

	function getSurferQueuePosition(address surferAddress, uint256 tokenId) public view returns (uint256) {
		return surferQueuePosition[surferAddress][tokenId];
	}

	function getSurfboardQueuePosition(address surfboardAddress, uint256 tokenId) public view returns (uint256) {
		return surfboardQueuePosition[surfboardAddress][tokenId];
	}

	function queueStatus() public view returns (SurfTypes.Surfer[] memory result) {
		uint256 resultIndex;
		result = new SurfTypes.Surfer[](getQueueLength());
		for (uint queueIndex = getQueueFront(); queueIndex <= getQueueBack(); queueIndex++) {
			result[resultIndex] = getSurferAtPosition(queueIndex);
			resultIndex++;
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
		addToSurfQueue(SurfTypes.Surfer(surferAddress, surferId, surfBoardAddress, surfboardId));
		surferQueuePosition[surferAddress][surferId] = getQueueBack();
		surfboardQueuePosition[surfBoardAddress][surfboardId] = getQueueBack();
		requestWaveSeedsIfNeeded();
		emit SurferAddedToQueue();
	}

	function getActionDistribution(address surferAddress, uint256 surferId) internal pure returns (uint8[] memory actionChances, SurfTypes.SurfAction[] memory actionDistribution) {
		uint8 size = 6;
		actionChances = new uint8[](size);
		actionDistribution = new SurfTypes.SurfAction[](size);

		actionChances[0] = 20;
		actionDistribution[0] = SurfTypes.SurfAction(SurfTypes.SPEED_UP, 5, 1);

		actionChances[1] = 20;
		actionDistribution[1] = SurfTypes.SurfAction(SurfTypes.SPEED_DOWN, -5, 1);

		actionChances[2] = 10;
		actionDistribution[2] = SurfTypes.SurfAction(SurfTypes.CUT_BACK, -4, 5);

		actionChances[3] = 10;
		actionDistribution[3] = SurfTypes.SurfAction(SurfTypes.AERIAL, -10, 15);

		actionChances[4] = 10;
		actionDistribution[4] = SurfTypes.SurfAction(SurfTypes.TUBE, -20, 20);

		actionChances[5] = 30;
		actionDistribution[5] = SurfTypes.SurfAction(SurfTypes.WIPEOUT, 0, 0);
	}

	/**
	 *
	 * Gamne engine logic
	 *
	 **/
	function canRun() public view returns (bool) {
		return waveSeeds.length > 0 && !isSurfQueueEmpty();
	}

	function runGame() external {
		if (canRun()) {
			uint256 waveSeed = getAvailableWaveSeed();
			uint256 queueProcessLength = getQueueLength() > currentWave.waveCapacity ? currentWave.waveCapacity : getQueueLength();

			while (queueProcessLength > 0) {
				SurfTypes.Surfer memory surfer = getFromSurfQueue();
				doRun(waveSeed, surfer);
				surferRunsLength[surfer.surferAddress][surfer.surferId]++;
				delete surferQueuePosition[surfer.surferAddress][surfer.surferId];
				delete surfboardQueuePosition[surfer.surfboardAddress][surfer.surfboardId];
				queueProcessLength--;
			}
			//Check if needs more waves
			if (!isSurfQueueEmpty()) {
				requestWaveSeedsIfNeeded();
			}

			emit WaveSurfEnd();
		} else {
			console.log("didnt run");
		}
	}

	/**
	 *
	 * Generates a random run log based on a seed
	 *
	 * @param waveSeed the wave seed, a uint256 that represents the randomness of this run
	 */
	function doRun(uint256 waveSeed, SurfTypes.Surfer memory surfer) public {
		uint8 treshold = NumberUtils.countDigits(waveSeed);
		uint8 currentRunSpecIndex = 0;
		uint32 waveSections = 0;
		uint32 actionProbability = 0;
		int32 currentSpeed = 100; //maybe influenced by the board and the surfer
		uint currentScore = 0;
		bool isWipeout;

		//Calculates total wave sections based on the random + the wave configuration
		(waveSections, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 2, treshold);
		waveSections = currentWave.waveMaxLength - (currentWave.waveMaxLength % waveSections);

		//Sets the basic actions every wave will ahve
		(currentSpeed, currentScore) = logAction(surfer, SurfTypes.SurfAction(SurfTypes.TAKE_OFF, 5, 0), currentSpeed, currentScore);
		(currentSpeed, currentScore) = logAction(surfer, SurfTypes.SurfAction(SurfTypes.BOTTOM_TURN, 5, 0), currentSpeed, currentScore);

		//Random actions
		//2 is the number of fixed actions
		for (uint8 waveSection = 2; waveSection < waveSections + 2; waveSection++) {
			(actionProbability, currentRunSpecIndex) = NumberUtils.extractDigits(waveSeed, currentRunSpecIndex, 2, treshold);
			(currentSpeed, currentScore, isWipeout) = logRandomAction(surfer, actionProbability, currentSpeed, currentScore);
			if (isWipeout || currentSpeed < int32(currentWave.waveSpeed)) {
				//Close run
				break;
			}
		}
		addScore(surfer.surferAddress, surfer.surferId, currentScore);
		increaseLevel(surfer, currentScore);
	}

	function logRandomAction(
		SurfTypes.Surfer memory surfer,
		uint32 actionProbability,
		int32 currentSpeed,
		uint currentScore
	) internal returns (int32 newSpeed, uint newScore, bool isWipeout) {
		SurfTypes.SurfAction memory currentAction = getActionByProbability(actionProbability, surfer.surferAddress, surfer.surferId);
		(newSpeed, newScore) = logAction(surfer, currentAction, currentSpeed, currentScore);
		isWipeout = SurfTypes.WIPEOUT == currentAction.name;
	}

	function logAction(
		SurfTypes.Surfer memory surfer,
		SurfTypes.SurfAction memory currentAction,
		int32 currentSpeed,
		uint currentScore
	) internal returns (int32 newSpeed, uint newScore) {
		(newSpeed, newScore) = processAction(currentAction, currentSpeed, currentScore, 0, 0);
		surferLogs[surfer.surferAddress][surfer.surferId][surferRunsLength[surfer.surferAddress][surfer.surferId]].push(
			SurfTypes.RunLog(block.timestamp, currentAction.name, newSpeed, newScore)
		);
	}

	function getActionByProbability(uint32 probability, address surferAddress, uint256 surferId) internal pure returns (SurfTypes.SurfAction memory surfAction) {
		(uint8[] memory actionChances, SurfTypes.SurfAction[] memory actionDistribution) = getActionDistribution(surferAddress, surferId);
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

	/**
	 *
	 * This function processes an action and applies modifiers to score and speed of the surfer
	 * based on the modifiers + current wave conditions
	 *
	 */
	function processAction(
		SurfTypes.SurfAction memory currentAction,
		int32 currentSpeed,
		uint currentScore,
		int32 speedModifier,
		uint scoreModifier
	) internal view returns (int32 newSpeed, uint newScore) {
		newSpeed = currentSpeed + currentAction.speedChange + speedModifier;
		newScore = currentScore + ((currentAction.scoreChange + scoreModifier) * currentWave.wavePower);
	}

	/**
	 *
	 * Waves logic
	 *
	 */
	function addWaveSeed(uint waveSeed) internal {
		waveSeeds.push(waveSeed);
	}

	function getAvailableWaveSeed() internal returns (uint256 waveSeed) {
		waveSeed = waveSeeds[waveSeeds.length - 1];
		waveSeeds.pop();
	}

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

	function surfForecastServiceResponseToSurfWave(bytes memory data) internal pure returns (SurfTypes.SurfWave memory surfWave) {
		uint32 waveMaxLength;
		uint32 wavePower;
		uint32 waveSpeed;
		uint32 waveCapacity;
		uint256 startPos = 0;
		(waveMaxLength, startPos) = data.toUint_Dynamic(startPos);
		(wavePower, startPos) = data.toUint_Dynamic(startPos);
		(waveSpeed, startPos) = data.toUint_Dynamic(startPos);
		(waveCapacity, startPos) = data.toUint_Dynamic(startPos);
		surfWave = SurfTypes.SurfWave(SurfTypes.SUPER_TUBOS, waveMaxLength, wavePower, waveSpeed, SurfTypes.WaveSide.Left, waveCapacity);
	}

	function handleForecastServiceResponse(bytes32 /*requestId*/, bytes memory response) external override {
		/* shouuld use request id to verify */
		setNextWaveConditions(response);
		emit WaveConditionsSet();
	}

	/**
	 * Set wave will be set daily by the integration with Weather Forecast API
	 */
	function setNextWaveConditions(bytes memory response) internal {
		currentWave = surfForecastServiceResponseToSurfWave(response);
	}

	function getCurrentWaveConditions() public view returns (SurfTypes.SurfWave memory) {
		return currentWave;
	}

	/**
	 *
	 * Modifiers
	 *
	 */
	modifier onlyNFTOwner(address collectionNFTaddress, uint256 tokenId) {
		ICollectionNFT collectionNFT = ICollectionNFT(collectionNFTaddress);
		if (msg.sender != collectionNFT.getOwner(tokenId)) {
			revert("Not owner of the NFT");
		}
		_;
	}

	/*** Dynamic NFT Maangement */
	//traits
	bytes32 constant surfLevel = bytes32("Surf Level");
	bytes32 constant surfExperience = bytes32("Surf Experience");
	bytes32 constant special = bytes32("Special");

	//Surfboard
	bytes32 constant surfboardSpeed = bytes32("Speed");

	uint256 constant EXPERIENCE_BY_LEVEL_FACTOR = 50;

	function increaseLevel(SurfTypes.Surfer memory surfer, uint score) internal {
		bytes32[] memory traitKeys = new bytes32[](2);
		traitKeys[0] = surfLevel;
		traitKeys[1] = surfExperience;
		ICollectionNFT surferContract = ICollectionNFT(surfer.surferAddress);
		uint256 surferId = surfer.surferId;
		bytes32[] memory traitValues = surferContract.getTraitValues(surferId, traitKeys);
		uint256 currentLevel = uint(traitValues[0]);
		uint256 currentExperience = uint(traitValues[1]);
		uint256 totalExperience = currentExperience + score;

		uint256 newLevel = calculateLevel(currentLevel, totalExperience);
		if (newLevel > currentLevel) {
			surferContract.setTrait(surferId, Types.Trait(true, Types.TraitType.Number, surfLevel, bytes32(newLevel)));
		}
		surferContract.setTrait(surferId, Types.Trait(true, Types.TraitType.Number, surfExperience, bytes32(totalExperience)));
	}

	function calculateLevel(uint256 currentLevel, uint totalExperience) public pure returns (uint256 level) {
		uint experienceNeeded = currentLevel == 0 ? EXPERIENCE_BY_LEVEL_FACTOR : currentLevel * currentLevel * EXPERIENCE_BY_LEVEL_FACTOR;

		while (totalExperience >= experienceNeeded) {
			level++; // Increase level
			experienceNeeded = level * level * EXPERIENCE_BY_LEVEL_FACTOR;
		}

		return level;
	}

	function withdraw() external override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
