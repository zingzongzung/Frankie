// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../libraries/BytesToValue.sol";
import "../surf/SurfTypes.sol";

library SurfForecastLib {
	using BytesToValue for bytes;

	function surfForecastServiceResponseToSurfWave(bytes memory data) external pure returns (SurfTypes.SurfWave memory surfWave) {
		uint32 waveMaxLength;
		uint32 wavePower;
		uint32 waveSpeed;
		uint32 waveCapacity;
		uint256 startPos = 0;
		(waveMaxLength, startPos) = data.toUint_Dynamic(startPos);
		(wavePower, startPos) = data.toUint_Dynamic(startPos);
		(waveSpeed, startPos) = data.toUint_Dynamic(startPos);
		(waveCapacity, startPos) = data.toUint_Dynamic(startPos);
		surfWave = SurfTypes.SurfWave(waveMaxLength, wavePower, waveSpeed);
	}
}
