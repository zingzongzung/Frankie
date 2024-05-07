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

	struct NFTV2 {
		string name;
		uint genes;
		uint8 genesLength;
		uint32[] chancesGene;
		TraitV2[] traits;
	}

	struct TraitV2 {
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
