// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SurfTypes.sol";

contract SurfGameScoreManager {
	//HiScores
	uint private currentRound;
	//This will hold the information about how many participants are in a given round, useful for querying
	mapping(uint => uint) private roundPlayers;

	//This indexes the logs of an address + token id (a player ) + the round, so that when we add
	//we can go directly to the round score of this address and overwrite the round score there
	mapping(uint => mapping(address => mapping(uint => uint))) private playerRoundIndex;

	//Based on the current round + surfer index we will have  a score that should be manipulated
	mapping(uint => mapping(uint => SurfTypes.ScoreLog)) private roundScores;

	/***
	 * Scores Handling
	 */

	function startNewRound() external {
		currentRound += 1;
	}

	function getCurrentRound() external view returns (uint) {
		return currentRound;
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

	function getScore(uint roundIndex, uint playerIndex) internal view returns (SurfTypes.ScoreLog memory) {
		return roundScores[roundIndex][playerIndex];
	}

	function getRoundScore(uint roundIndex) external view returns (SurfTypes.ScoreLog[] memory _roundScores) {
		uint roundTotalPlayers = roundPlayers[roundIndex];
		_roundScores = new SurfTypes.ScoreLog[](roundTotalPlayers);
		for (uint playerIndex = 0; playerIndex < roundTotalPlayers; playerIndex++) {
			_roundScores[playerIndex] = getScore(roundIndex, playerIndex + 1);
		}
	}
}
