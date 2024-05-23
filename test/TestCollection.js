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
  async function deployContracts(collectionPrice) {
    const [owner, otherAccount] = await ethers.getSigners();

    const {
      mockCoordinator,
      nftRandomManager,
      shopManager,
      gameManager,
      passManager,
      passConfig,
      passNFT,
      simulateMockResponse,
    } = await deployContractsInfrastructure();

    const collectionName = "Ninjas of Sydney";

    const { collection, collectionNFT, CollectionConfigFactory } =
      await deployCollection(
        0,
        collectionName,
        setupCharacterAttributes,
        nftRandomManager,
        shopManager,
        gameManager,
        passManager,
        passNFT,
        collectionPrice
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
      simulateMockResponse,
      collectionName,
    };
  }

  /**
   *
   * Test scenarios for pass and pass usage
   *
   */
  describe("Pass Management", function () {
    it("Can't edit pass after it has been used", async function () {
      const { passManager, passNFT, collectionNFT } = await deployContracts();

      await expect(
        passManager.setPassCollectionAddress(
          passNFT,
          0,
          collectionNFT,
          new Uint8Array()
        )
      ).to.be.revertedWith("Trying to set collection address on a used pass");
    });

    it("Can't deploy another collection after a pass has been used", async function () {
      const {
        passManager,
        passNFT,
        collectionNFT,
        nftRandomManager,
        shopManager,
        gameManager,
      } = await deployContracts();

      await expect(
        deployCollection(
          0,
          "collectionName",
          setupCharacterAttributes,
          nftRandomManager,
          shopManager,
          gameManager,
          passManager,
          passNFT
        )
      ).to.be.revertedWith("This pass has been used already");
    });

    it("Pass that was used to deploy the collection has both the collection confg name and collection nft address correctly set", async function () {
      const { passNFT, passConfig, collectionNFT, collectionName } =
        await deployContracts();
      const knownFields = await passConfig.getPassTraits();

      const passTraitCollectionName = bytes32ToString(
        await passNFT.getTraitValue(0, knownFields.collectionLabel)
      );
      const passTraitCollectionNFTAddress = await passNFT.getTraitValue(
        0,
        knownFields.collectionAddressLabel
      );

      let passTraitCollectionNFTAddressWithoutExtraZeros =
        passTraitCollectionNFTAddress.replace(/0+$/, "");

      expect(
        passTraitCollectionName,
        "The collection name should have value "
      ).to.equal(collectionName);

      expect(
        passTraitCollectionNFTAddressWithoutExtraZeros.toLowerCase(),
        "The final collection address should have value "
      ).to.equal(collectionNFT.target.toLowerCase());
    });

    it("When a pass is minted his traits are set to empty", async function () {
      const { passManager, passNFT, passConfig, otherAccount } =
        await deployContracts();

      let newPassCollectionName, newPassCollectionAddress;

      const knownFields = await passConfig.getPassTraits();

      //Mint a pass for otherAccount
      await passManager.connect(otherAccount).mintNFT(passNFT.target, "Pass 2");

      newPassCollectionName = bytes32ToString(
        await passNFT.getTraitValue(1, knownFields.collectionLabel)
      );
      newPassCollectionAddress = bytes32ToString(
        await passNFT.getTraitValue(1, knownFields.collectionAddressLabel)
      );

      //New pass has both name of collection and addres set to empty
      expect(
        newPassCollectionName,
        "The initial collection name for pass collection is not empty "
      ).to.equal("");
      expect(
        newPassCollectionAddress,
        "The initial collection address for pass collection is not empty "
      ).to.equal("");
    });
  });

  /**
   *
   * Tests collection permissions
   *
   */
  describe("Collection permissions", function () {
    it("Can't add traits after colection closed", async function () {
      const { collection } = await deployContracts();

      await expect(
        collection.addTextTrait(
          stringToBytes32("TextTrait"),
          100,
          stringToBytes32("Default Value")
        )
      ).to.be.revertedWith("This collection is already closed");
    });

    it("Can't change price after colection closed", async function () {
      const [owner, otherAccount] = await ethers.getSigners();
      const { collection } = await deployContracts();

      await expect(
        collection.connect(otherAccount).setPrice(100)
      ).to.be.revertedWith(
        "Not the owner of the pass that has the owneship of this collection"
      );
    });

    it("Can't change price of the pass", async function () {
      const [owner, otherAccount] = await ethers.getSigners();
      const { passConfig } = await deployContracts();

      await expect(passConfig.connect(otherAccount).setPrice(100)).to.be
        .reverted;
    });

    it("Can change price of a collection if is the owner of the pass that minted it", async function () {
      const [owner, otherAccount] = await ethers.getSigners();
      const { collection, passNFT } = await deployContracts();

      await passNFT.safeTransferFrom(owner, otherAccount, 0);

      await expect(collection.connect(otherAccount).setPrice(100)).not.to.be
        .reverted;
    });
    it("Can change the price of pass if it is its owner", async function () {
      const { passConfig } = await deployContracts();

      await expect(passConfig.setPrice(100)).not.to.be.reverted;
    });
  });

  /**
   *
   * Tests the collection generation
   *
   */
  describe("Collection generation", function () {
    it("Get tokens by owner", async function () {
      const {
        passManager,
        passNFT,
        collectionNFT,
        nftRandomManager,
        shopManager,
        gameManager,
      } = await deployContracts(100000000000);

      const [owner, otherAccount] = await ethers.getSigners();

      await passManager.mintNFT(passNFT.target, "Pass 1");
      await passManager.mintNFT(passNFT.target, "Pass 2");
      await passManager.mintNFT(passNFT.target, "Pass 3");

      const ownerPasses = JSON.stringify(
        await passNFT.getTokensOwnedBy(owner),
        bigIntParser
      );

      await passManager.connect(otherAccount).mintNFT(passNFT.target, "Pass 4");
      await passManager.connect(otherAccount).mintNFT(passNFT.target, "Pass 5");

      const otherAccountPasses = JSON.stringify(
        await passNFT.getTokensOwnedBy(otherAccount),
        bigIntParser
      );

      expect(
        ownerPasses,
        "The generated trait list is not as expected "
      ).to.equal('["0","1","2","3"]');
      expect(
        otherAccountPasses,
        "The generated trait list is not as expected "
      ).to.equal('["4","5"]');
    });

    it("Is able to get the token URI ", async function () {
      const {
        collectionNFT,
        shopManager,
        simulateMockResponse,
        nftRandomManager,
        collection,
      } = await deployContracts();

      await shopManager.mintNFT(collectionNFT.target, `Token `, {
        value: ethers.parseEther("0.000000000000001"),
      });

      await simulateMockResponse();

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
        collectionNFT,
        shopManager,
        simulateMockResponse,
        expectedToken,
      } = await deployContracts();

      const result = await shopManager.getCollectionPrice(collectionNFT.target);
      // console.log(result); // divide by 10**18 to get the AVAX Value

      await shopManager.mintNFT(collectionNFT.target, `Token `, {
        value: ethers.parseEther("0.9999"),
      });

      await simulateMockResponse();

      const nftJSON = await collectionNFT.getNFTDetails(0);
      const nftJSONString = JSON.stringify(nftJSON, bigIntParser);

      expect(
        nftJSONString,
        "Attributes expected different from the generated ones "
      ).to.equal(expectedToken);
    });

    it("Shops/mint and rerolls trait", async function () {
      const {
        collectionNFT,
        owner,
        shopManager,
        simulateMockResponse,
        nftRandomManager,
        gameManager,
        expectedToken,
      } = await deployContracts();

      await shopManager.mintNFT(collectionNFT.target, `Token `, {
        value: ethers.parseEther("0.9999"),
      });

      await simulateMockResponse();

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
        simulateMockResponse,
        nftRandomManager,
        expectedToken,
      } = await deployContracts();

      const result = await shopManager.getCollectionPrice(collectionNFT.target);

      await shopManager.mintNFT(collectionNFT.target, `Token `);

      await simulateMockResponse();

      const nftJSON = await collectionNFT.getNFTDetails(0);
      const nftJSONString = JSON.stringify(nftJSON, (key, value) =>
        typeof value === "bigint" ? value.toString() : value
      );

      expect(nftJSONString, "Attributes not as expected").to.equal(
        expectedToken
      );
    });
  });

  /**
   *
   * Tests the collection royalties
   *
   */
  describe("Collection Royalties", function () {
    it("Can't mint a collection if not enough funds are sent", async function () {
      const priceInUSD = 20000; //200 dollars
      const { collectionNFT, shopManager } = await deployContracts(priceInUSD);

      const result = await shopManager.getCollectionPrice(collectionNFT.target);
      const priceCollectionInAvax = Number(result) / 10 ** 18;

      await expect(
        shopManager.mintNFT(collectionNFT.target, `Token `, {
          value: ethers.parseEther("2"),
        })
      ).to.be.revertedWith("Not enough funds sent!");
    });

    it("Can mint a collection when enough funds are sent", async function () {
      const priceInUSD = 20000; //200 dollars
      const { collectionNFT, shopManager } = await deployContracts(priceInUSD);

      const result = await shopManager.getCollectionPrice(collectionNFT.target);
      const priceCollectionInAvax = Number(result) / 10 ** 18;

      await expect(
        await shopManager.mintNFT(collectionNFT.target, `Token `, {
          value: ethers.parseEther(
            roundUpToDecimalPlace(priceCollectionInAvax, 10).toString()
          ),
        })
      ).to.not.be.reverted;
    });

    it("Royalties are paid", async function () {
      const [owner, otherAccount] = await ethers.getSigners();
      const priceInUSD = 20000; //200 dollars
      const { collectionNFT, shopManager } = await deployContracts(priceInUSD);

      const initialOwnerBalance = await ethers.provider.getBalance(
        owner.address
      );

      const result = await shopManager.getCollectionPrice(collectionNFT.target);
      const priceCollectionInAvax = Number(result) / 10 ** 18;

      await shopManager
        .connect(otherAccount)
        .mintNFT(collectionNFT.target, `Token `, {
          value: ethers.parseEther(
            roundUpToDecimalPlace(priceCollectionInAvax, 10).toString()
          ),
        });

      const afterOwnerBalance = await ethers.provider.getBalance(owner.address);
      expect(afterOwnerBalance).to.be.greaterThan(initialOwnerBalance);
    });

    it("Royalties are paid to the person that owns the pass and only that", async function () {
      const [owner, ownerOfPass, mintingAddress] = await ethers.getSigners();
      const priceInUSD = 20000; //200 dollars
      const { collectionNFT, shopManager, passNFT } = await deployContracts(
        priceInUSD
      );

      //Transfer pass to new owner
      await passNFT.safeTransferFrom(owner, ownerOfPass, 0);

      const initialOwnerBalance = await ethers.provider.getBalance(
        owner.address
      );
      const initialPassOwnerBalance = await ethers.provider.getBalance(
        ownerOfPass.address
      );

      const result = await shopManager.getCollectionPrice(collectionNFT.target);
      const priceCollectionInAvax = Number(result) / 10 ** 18;

      await shopManager
        .connect(mintingAddress)
        .mintNFT(collectionNFT.target, `Token `, {
          value: ethers.parseEther(
            roundUpToDecimalPlace(priceCollectionInAvax, 10).toString()
          ),
        });

      const afterOwnerBalance = await ethers.provider.getBalance(owner.address);
      const afterPassOwnerBalance = await ethers.provider.getBalance(
        ownerOfPass.address
      );

      expect(initialOwnerBalance).to.be.eq(afterOwnerBalance);
      expect(afterPassOwnerBalance).to.be.greaterThan(initialPassOwnerBalance);
    });

    it("Shop manager fees are whitdrawable only once", async function () {
      const [owner, ownerOfPass, mintingAddress] = await ethers.getSigners();
      const priceInUSD = 20000; //200 dollars
      const { collectionNFT, shopManager, passNFT } = await deployContracts(
        priceInUSD
      );

      //Transfer pass to new owner
      await passNFT.safeTransferFrom(owner, ownerOfPass, 0);

      const initialOwnerBalance = await ethers.provider.getBalance(
        owner.address
      );

      const result = await shopManager.getCollectionPrice(collectionNFT.target);
      const priceCollectionInAvax = Number(result) / 10 ** 18;

      await shopManager
        .connect(mintingAddress)
        .mintNFT(collectionNFT.target, `Token `, {
          value: ethers.parseEther(
            roundUpToDecimalPlace(priceCollectionInAvax, 10).toString()
          ),
        });

      await shopManager.withdraw();

      const afterOwnerBalance = await ethers.provider.getBalance(owner.address);

      expect(afterOwnerBalance).to.be.greaterThan(initialOwnerBalance);
      await expect(shopManager.withdraw()).to.be.revertedWith(
        "There are no taxes to be whitdrawn"
      );
    });
  });
});

const bigIntParser = (key, value) => {
  return typeof value === "bigint" ? value.toString() : value;
};

function roundUpToDecimalPlace(number, decimalPlaces) {
  const factor = Math.pow(10, decimalPlaces);
  return Math.ceil(number * factor) / factor;
}
