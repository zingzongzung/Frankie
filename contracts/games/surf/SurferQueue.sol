// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./SurfTypes.sol";

abstract contract SurferQueue {
	mapping(uint256 => SurfTypes.Surfer) private surferQueue;
	uint256 private front = 1;
	uint256 private back = 0;

	function addToSurfQueue(SurfTypes.Surfer memory data) public {
		back++;
		surferQueue[back] = data;
	}

	function getFromSurfQueue() public returns (SurfTypes.Surfer memory) {
		require(front <= back, "Queue is empty");

		SurfTypes.Surfer memory data = surferQueue[front];
		delete surferQueue[front];

		front++;
		return data;
	}

	function isSurfQueueEmpty() public view returns (bool) {
		return front > back;
	}

	function getQueueLength() public view returns (uint256 length) {
		if (front > back) {
			length = 0;
		} else {
			length = (back + 1) - front;
		}
	}
}
