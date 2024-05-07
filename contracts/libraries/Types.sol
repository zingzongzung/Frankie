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
		Trait[] traits;
	}

	struct Trait {
		Types.TraitType traitType;
		uint8 key;
		bool isDefined;
		uint32 value;
		bytes32 textValue;
	}

	struct Pass {
		address passAddress;
		uint passId;
	}
}
