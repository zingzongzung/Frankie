const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

//npx hardhat test ./test/basicNFT.js
describe("NFT Generator", function () {
  async function deployContracts() {
    const [owner, otherAccount] = await ethers.getSigners();

    const GenesisCollection = await ethers.getContractFactory(
      "GenesisCollection"
    );
    const genesisCollection = await GenesisCollection.deploy();

    const NFTRandomManager = await ethers.getContractFactory(
      "NFTRandomManager"
    );
    const nftRandomManager = await NFTRandomManager.deploy(
      /* VRF Subscription Id */ 5
    );

    const GenesisNFT = await ethers.getContractFactory("GenesisNFT");
    const genesisNFT = await GenesisNFT.deploy(
      owner.address,
      genesisCollection.target,
      nftRandomManager.target,
      "NFT Name",
      "GGGG"
    );

    const NFTManager = await ethers.getContractFactory("NFTManager");
    const nFTManager = await NFTManager.deploy(owner.address);

    await nFTManager.addManagedCollection(genesisNFT.target);
    await genesisNFT.setShopManagerAddress(nFTManager.target);

    await setupCharacterAttributes(genesisCollection);

    return { genesisCollection, genesisNFT, owner, nFTManager };
  }

  describe("Test an instance of a Collection NFT - GenesisNFT", function () {
    it("Shop ", async function () {
      const { genesisCollection, genesisNFT, owner, nFTManager } =
        await deployContracts();

      await nFTManager._mintNFT(genesisNFT.target, `Token `, {
        value: ethers.parseEther("0.0000000000000001"),
      });
    });

    it("Mint token Using Random", async function () {
      const { genesisCollection, genesisNFT, owner } = await deployContracts();

      let randomNumbers = [
        "23895781004589149129578100458914450004567867867856785990002450",
        "23895781004589149129578100458914450004567867867856785990110099",
      ];

      let nfts = [];

      for (let index = 0; index < randomNumbers.length; index++) {
        let randomNumber = randomNumbers[index];
        await genesisNFT.safeMintTest(
          owner.address,
          randomNumber,
          `Token ${index}`
        );
        let tokenId = index;
        const nftJSON = await genesisNFT.getNFTDetails(tokenId);

        nfts.push({ genes: randomNumber, attributes: [] });

        const TRAITS_INDEX = 4;

        //Trait Structure
        const TRAIT_TYPE_INDEX = 0;
        const TRAIT_KEY_INDEX = 1;
        const TRAIT_IS_DEFINED_INDEX = 2;
        const TRAIT_VALUE_INDEX = 3;
        let nftTraits = nftJSON[TRAITS_INDEX];

        for (let i = 0; i < nftTraits.length; i++) {
          let traitType = nftTraits[i][TRAIT_TYPE_INDEX];
          let traitKey = nftTraits[i][TRAIT_KEY_INDEX];
          let traitValue = nftTraits[i][TRAIT_VALUE_INDEX];
          let traitDefined = nftTraits[i][TRAIT_IS_DEFINED_INDEX];

          if (traitDefined) {
            let traitLabel = await genesisCollection.getTraitLabel(traitKey);

            let attribute = {
              trait_type: traitLabel,
              value:
                traitType == 1
                  ? traitValue
                  : await genesisCollection.getTraitOptionsLabel(
                      traitKey,
                      traitValue
                    ),
              image: await genesisCollection.getTraitOptionsImage(
                traitKey,
                traitValue
              ),
            };
            nfts[index].attributes.push(attribute);
          }
        }
      }
      let nftsString = JSON.stringify(
        nfts,
        (key, value) => (typeof value === "bigint" ? value.toString() : value) // return everything else unchanged
      );

      expect(
        nftsString,
        "Attributes for gene should have strenght 100 and arms blue and weapon and"
      ).to.equal(
        '[{"genes":"23895781004589149129578100458914450004567867867856785990002450","attributes":[{"trait_type":"Strength","value":"24","image":""},{"trait_type":"Strengtsh","value":"94","image":""},{"trait_type":"Arms","value":"Yellow","image":"<g class=\'monster-left-arm\'> <path id=\'Shape\' d=\'M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z\' transform=\'translate(-114.73)\' style=\'fill: #df4d60\' /></g><g class=\'monster-right-arm\'> <path id=\'Shape-2\' data-name=\'Shape\' d=\'M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z\' transform=\'translate(-114.73)\' style=\'fill: #df4d60\' /></g>"},{"trait_type":"Weapon","value":"Wand","image":""}]},{"genes":"23895781004589149129578100458914450004567867867856785990110099","attributes":[{"trait_type":"Strength","value":"100","image":""},{"trait_type":"Arms","value":"Blue","image":"<g class=\'monster-left-arm\'> <path id=\'Shape\' d=\'M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z\' transform=\'translate(-114.73)\' style=\'fill: #df4d60\' /></g><g class=\'monster-right-arm\'> <path id=\'Shape-2\' data-name=\'Shape\' d=\'M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z\' transform=\'translate(-114.73)\' style=\'fill: #df4d60\' /></g>"},{"trait_type":"Weapon","value":"Wand","image":""}]}]'
      );
    });
  });
});

async function setupCharacterAttributes(genesisCollectionInstance) {
  let armsPinkSVG =
    "<g class='monster-left-arm'> <path id='Shape' d='M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z' transform='translate(-114.73)' style='fill: #df4d60' /></g><g class='monster-right-arm'> <path id='Shape-2' data-name='Shape' d='M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z' transform='translate(-114.73)' style='fill: #df4d60' /></g>";
  // Numerical attributes with rarity
  await genesisCollectionInstance.addNumberTrait(11, "Strength", 100, 0, 100);
  await genesisCollectionInstance.addNumberTrait(12, "Strengtsh", 1, 0, 100);

  // Categorical attributes with respective rarities for each category
  await genesisCollectionInstance.addOptionsWithImageTrait(
    13,
    "Arms",
    100,
    ["Pink", "Grey", "Yellow", "Red", "Blue"],
    [10, 20, 30, 20, 20],
    [armsPinkSVG, armsPinkSVG, armsPinkSVG, armsPinkSVG, armsPinkSVG]
  );

  await genesisCollectionInstance.addOptionsTrait(
    15,
    "Weapon",
    100,
    ["Sword", "Axe", "Bow", "Spear", "Wand"],
    [10, 20, 30, 20, 20]
  );
}
