// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Types {
	//Traits
	enum TraitType {
		Options,
		Number,
		OptionsWithImage,
		Text
	}

	struct NFT {
		string name;
		uint genes;
		uint8 genesLength;
		uint32[] chancesGene;
	}

	struct Trait {
		bool isDefined;
		Types.TraitType traitType;
		bytes32 key;
		bytes32 value;
	}

	struct Pass {
		address passAddress;
		uint passId;
	}
}
