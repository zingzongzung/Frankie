// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SurfTypes.sol";
import "../../collection/collection_config/ICollectionConfig.sol";

library SurfLib {
	/**
	 *
	 * Calculates new level based of current level + current experience
	 *
	 * @param currentLevel The current level
	 * @param totalExperience The total experience
	 */
	function calculateLevel(uint256 currentLevel, uint totalExperience) internal pure returns (uint256 level) {
		uint experienceNeeded = currentLevel == 0 ? SurfTypes.EXPERIENCE_BY_LEVEL_FACTOR : currentLevel * currentLevel * SurfTypes.EXPERIENCE_BY_LEVEL_FACTOR;

		while (totalExperience >= experienceNeeded) {
			level++; // Increase level
			experienceNeeded = level * level * SurfTypes.EXPERIENCE_BY_LEVEL_FACTOR;
		}

		return level;
	}

	/**
	 *
	 * Gets the surfer currennt level and experience
	 *
	 */
	function getSurferTraits(ICollectionNFT surferContract, SurfTypes.Surfer memory surfer) internal view returns (uint256 currentLevel, uint256 currentExperience) {
		bytes32[] memory traitKeys = new bytes32[](2);
		traitKeys[0] = SurfTypes.SURF_LEVEL;
		traitKeys[1] = SurfTypes.SURF_EXPERIENCE;
		bytes32[] memory traitValues = surferContract.getTraitValues(surfer.surferId, traitKeys);
		currentLevel = uint(traitValues[0]);
		currentExperience = uint(traitValues[1]);
	}

	function getBoardSpeed(address surfboardAddress, uint surfboardId) internal view returns (uint boardSpeed) {
		ICollectionNFT surfboardContract = ICollectionNFT(surfboardAddress);
		return uint(surfboardContract.getTraitValue(surfboardId, SurfTypes.BOARD_SPEED));
	}

	/**
	 *
	 * @param probability the probability factor that was obtained through vrf
	 * @param surferAddress the surfer this action belongs to
	 * @param surferId  the surfer this action belongs to
	 */
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

	function processAction(
		SurfTypes.SurfAction memory currentAction,
		int32 currentSpeed,
		uint currentScore,
		int32 speedModifier,
		uint scoreModifier
	) internal pure returns (int32 newSpeed, uint newScore) {
		newSpeed = currentSpeed + currentAction.speedChange + speedModifier;
		newScore = currentScore + ((currentAction.scoreChange + scoreModifier));
	}

	/**
	 *
	 * Returns the list of possible actions.
	 * For now every surfer has the same list of possible actions.
	 *
	 * In the future we would tweak this distribution based on surfer stats
	 */
	function getActionDistribution(
		address /*surferAddress*/,
		uint256 /*surferId*/
	) internal pure returns (uint8[] memory actionChances, SurfTypes.SurfAction[] memory actionDistribution) {
		//This should be dynamic
		uint8 size = 7;
		actionChances = new uint8[](size);
		actionDistribution = new SurfTypes.SurfAction[](size);

		actionChances[0] = 24;
		actionDistribution[0] = SurfTypes.SurfAction(SurfTypes.SPEED_UP, 5, 1);

		actionChances[1] = 25;
		actionDistribution[1] = SurfTypes.SurfAction(SurfTypes.SPEED_DOWN, -5, 1);

		actionChances[2] = 20;
		actionDistribution[2] = SurfTypes.SurfAction(SurfTypes.CUT_BACK, -4, 5);

		actionChances[3] = 10;
		actionDistribution[3] = SurfTypes.SurfAction(SurfTypes.AERIAL, -10, 15);

		actionChances[4] = 10;
		actionDistribution[4] = SurfTypes.SurfAction(SurfTypes.TUBE, -20, 20);

		actionChances[5] = 10;
		actionDistribution[5] = SurfTypes.SurfAction(SurfTypes.WIPEOUT, 0, 0);

		actionChances[6] = 1;
		actionDistribution[6] = SurfTypes.SurfAction(SurfTypes.SHARK, 0, 0);
	}
}
