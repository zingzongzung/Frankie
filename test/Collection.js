const {} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { string } = require("hardhat/internal/core/params/argumentTypes");

const {
  deployContractsInfrastructure,
  deployCollection,
  stringToBytes32,
  bytes32ToString,
} = require("./Configs/CommonPreparation.js");

const {
  setupCharacterAttributes,
} = require("./Configs/BaseCollectionConfiguration.js");

//npx hardhat test ./test/Collection.js
describe("NFT collectionNFT", function () {
  /**
   *
   * @returns all deployed contracts
   */
  async function deployContracts() {
    const [owner, otherAccount] = await ethers.getSigners();

    const {
      mockCoordinator,
      nftRandomManager,
      shopManager,
      gameManager,
      passManager,
      passConfig,
      passNFT,
    } = await deployContractsInfrastructure();

    const { collection, collectionNFT, CollectionConfigFactory } =
      await deployCollection(
        0,
        "Ninjas of Sydney",
        setupCharacterAttributes,
        nftRandomManager,
        shopManager,
        gameManager,
        passManager,
        passConfig,
        passNFT
      );

    const expectedToken =
      '[["Token ","0","0",[]],[[true,"1","0x537472656e677468000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000018"],[true,"1","0x4465787465727479000000000000000000000000000000000000000000000000","0x000000000000000000000000000000000000000000000000000000000000005e"],[true,"2","0x41726d7300000000000000000000000000000000000000000000000000000000","0x59656c6c6f770000000000000000000000000000000000000000000000000000"],[true,"0","0x576561706f6e0000000000000000000000000000000000000000000000000000","0x466f726b00000000000000000000000000000000000000000000000000000000"],[true,"3","0x5465787454726169740000000000000000000000000000000000000000000000","0x44656661756c742056616c756500000000000000000000000000000000000000"]]]';

    return {
      collection,
      collectionNFT,
      owner,
      otherAccount,
      shopManager,
      mockCoordinator,
      nftRandomManager,
      gameManager,
      passManager,
      expectedToken,
      passNFT,
      passConfig,
      CollectionConfigFactory,
    };
  }

  describe("Test Forge", function () {
    it("Mints a Pass and updates it once collection is minted", async function () {
      const {
        passManager,
        passNFT,
        passConfig,
        otherAccount,
        CollectionConfigFactory,
        nftRandomManager,
        mockCoordinator,
      } = await deployContracts();

      const collectionName = "Samurais of Sydney";
      let initialCollectionValue, finalCollectionValue;
      let initialCollectionAddressValue, finalCollectionAddressValue;

      const knownFields = await passConfig.getKnownFields();

      //Mint a pass for otherAccount
      await passManager.connect(otherAccount).mintNFT(passNFT.target, "Pass 2");
      initialCollectionValue = bytes32ToString(
        await passNFT.getTraitValue(1, knownFields.collectionLabel)
      );

      initialCollectionValue = bytes32ToString(
        await passNFT.getTraitValue(1, knownFields.collectionLabel)
      );
      initialCollectionAddressValue = bytes32ToString(
        await passNFT.getTraitValue(1, knownFields.collectionAddressLabel)
      );

      const samuraisCollectionName = stringToBytes32("Samurais of Sydney");

      //Sign a message
      const TEST_MESSAGE = "Samurais of Sydney";
      const hashedMessage = ethers.hashMessage(TEST_MESSAGE);
      const signature = await otherAccount.signMessage(TEST_MESSAGE);

      await CollectionConfigFactory.deploy(
        passManager.target,
        passNFT.target,
        1,
        hashedMessage,
        signature,
        samuraisCollectionName
      );

      finalCollectionValue = bytes32ToString(
        await passNFT.getTraitValue(1, knownFields.collectionLabel)
      );

      finalCollectionAddressValue = await passNFT.getTraitValue(
        1,
        knownFields.collectionAddressLabel
      );

      finalCollectionAddressValue = finalCollectionAddressValue.replace(
        /0+$/,
        ""
      );

      expect(
        initialCollectionValue,
        "The initial collection value for pass collection is not empty "
      ).to.equal("");
      expect(
        finalCollectionValue,
        "The initial collection value for pass collection should have value "
      ).to.equal(collectionName);

      expect(
        initialCollectionValue,
        "The initial collection address value for pass collection is not empty "
      ).to.equal("");
      expect(
        finalCollectionAddressValue.toLowerCase(),
        "The initial collection address value for pass collection should have value "
      ).to.equal(passNFT.target.toLowerCase());
    });
    it("Is able to get the token URI ", async function () {
      const {
        collectionNFT,
        shopManager,
        mockCoordinator,
        nftRandomManager,
        collection,
      } = await deployContracts();

      await shopManager.mintNFT(collectionNFT.target, `Token `, {
        value: ethers.parseEther("0.9999"),
      });

      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [23895781004589149129578100458914450004567867867856785990002450n]
      );

      const nftJSONAttributes = (await collectionNFT.getNFTDetails(0))[1];

      let nft = { traits: [] };
      for (let i = 0; i < nftJSONAttributes.length; i++) {
        const attribute = nftJSONAttributes[i];
        if (attribute.isDefined) {
          let traitLabel = bytes32ToString(attribute.key);
          let traitValue;
          let traitImage;
          if (attribute.traitType === 1n) {
            traitValue = parseInt(attribute.value, 16);
          } else {
            traitValue = bytes32ToString(attribute.value);
            if (attribute.traitType === 2n) {
              traitImage = await collection.getTraitOptionsImage(
                attribute.key,
                attribute.value
              );
            }
          }
          nft.traits.push({ traitLabel, traitValue, traitImage });
        }
      }
      let result = JSON.stringify(nft);
      let expetedResult =
        '{"traits":[{"traitLabel":"Strength","traitValue":24},{"traitLabel":"Dexterty","traitValue":94},{"traitLabel":"Arms","traitValue":"Yellow","traitImage":"<g class=\'monster-left-arm-yellow\'> <path id=\'Shape\' d=\'M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z\' transform=\'translate(-114.73)\' style=\'fill: #df4d60\' /></g><g class=\'monster-right-arm\'> <path id=\'Shape-2\' data-name=\'Shape\' d=\'M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z\' transform=\'translate(-114.73)\' style=\'fill: #df4d60\' /></g>"},{"traitLabel":"Weapon","traitValue":"Fork"},{"traitLabel":"TextTrait","traitValue":"Default Value"}]}';

      expect(result, "The generated trait list is not as expected ").to.equal(
        expetedResult
      );
    });

    it("Shop/mint  an item that costs more than 0", async function () {
      const {
        collection,
        collectionNFT,
        owner,
        shopManager,
        mockCoordinator,
        nftRandomManager,
        gameManager,
        expectedToken,
      } = await deployContracts();

      const result = await shopManager.getCollectionPrice(collectionNFT.target);
      // console.log(result); // divide by 10**18 to get the AVAX Value

      await shopManager.mintNFT(collectionNFT.target, `Token `, {
        value: ethers.parseEther("0.9999"),
      });

      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [23895781004589149129578100458914450004567867867856785990002450n]
      );

      const nftJSON = await collectionNFT.getNFTDetails(0);
      const nftJSONString = JSON.stringify(nftJSON, bigIntParser);

      expect(
        nftJSONString,
        "Attributes expected different from the generated ones "
      ).to.equal(expectedToken);
    });

    it("Shops/mint and rerolls trait", async function () {
      const {
        collection,
        collectionNFT,
        owner,
        shopManager,
        mockCoordinator,
        nftRandomManager,
        gameManager,
        expectedToken,
      } = await deployContracts();

      await shopManager.mintNFT(collectionNFT.target, `Token `, {
        value: ethers.parseEther("0.9999"),
      });

      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [23895781004589149129578100458914450004567867867856785990002450n]
      );

      let nftJSON = await collectionNFT.getNFTDetails(0);
      let nftJSONString = JSON.stringify(nftJSON, bigIntParser);

      expect(
        nftJSONString,
        "Attributes expected different from the generated ones before reroll"
      ).to.equal(expectedToken);

      //Rerol two traits
      await gameManager.rerollAttribute(collectionNFT, 0, nftJSON[1][0].key);
      await gameManager.rerollAttribute(collectionNFT, 0, nftJSON[1][2].key);
      //await gameManager.rerollAttribute(collectionNFT, 0, 13);

      nftJSON = await collectionNFT.getNFTDetails(0);
      nftJSONString = JSON.stringify(nftJSON, bigIntParser);
      //console.log(nftJSONString);
      const expectedTokenAfterReroll =
        '[["Token ","0","0",[]],[[true,"1","0x537472656e677468000000000000000000000000000000000000000000000000","0x0000000000000000000000000000000000000000000000000000000000000063"],[true,"1","0x4465787465727479000000000000000000000000000000000000000000000000","0x000000000000000000000000000000000000000000000000000000000000005e"],[true,"2","0x41726d7300000000000000000000000000000000000000000000000000000000","0x426c756500000000000000000000000000000000000000000000000000000000"],[true,"0","0x576561706f6e0000000000000000000000000000000000000000000000000000","0x466f726b00000000000000000000000000000000000000000000000000000000"],[true,"3","0x5465787454726169740000000000000000000000000000000000000000000000","0x44656661756c742056616c756500000000000000000000000000000000000000"]]]';

      expect(
        nftJSONString,
        "Attributes expected different from the generated ones after reroll"
      ).to.equal(expectedTokenAfterReroll);
    });

    it("Mint nft for free", async function () {
      const {
        collection,
        collectionNFT,
        owner,
        shopManager,
        mockCoordinator,
        nftRandomManager,
        expectedToken,
      } = await deployContracts();

      await collection.setCollectionAttributes(0, 0, 0);
      const result = await shopManager.getCollectionPrice(collectionNFT.target);

      await shopManager.mintNFT(collectionNFT.target, `Token `);

      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [23895781004589149129578100458914450004567867867856785990002450n]
      );

      const nftJSON = await collectionNFT.getNFTDetails(0);
      const nftJSONString = JSON.stringify(nftJSON, (key, value) =>
        typeof value === "bigint" ? value.toString() : value
      );

      expect(
        nftJSONString,
        "Attributes for gene should have strenght 100 and arms blue and weapon and"
      ).to.equal(expectedToken);
    });
  });
});

const bigIntParser = (key, value) => {
  return typeof value === "bigint" ? value.toString() : value;
};
