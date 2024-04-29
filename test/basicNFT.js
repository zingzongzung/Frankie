const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("NFT Generator", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployContracts() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const GenesisCollection = await ethers.getContractFactory(
      "GenesisCollection"
    );
    const genesisCollection = await GenesisCollection.deploy();

    const BasicNFT = await ethers.getContractFactory("BasicNFT");
    const basicNFT = await BasicNFT.deploy(
      owner.address,
      genesisCollection.target
    );

    await setupCharacterAttributes(genesisCollection);

    return { genesisCollection, basicNFT, owner };
  }

  describe("Basic NFT", function () {
    it("Mint token with genes 238957810045891491295781004589144500045045000450", async function () {
      const { genesisCollection, basicNFT, owner } = await deployContracts();
      let randomNumbers = [
        "23895781004589149129578100458914450004567867867856785995002450",
        // "23895781004589149112352957810045891445000456778885695045000450",
        // "23895781004589149129578167788004589144500345634564563456045045000450",
        // "238957810045891491295781004589144598900044564356346345634565045000450",
        // "238957810045891491295781004589144500057450578567986789678945000450",
        // "238957810067845891491295781004589144500055430945045000345634563456450",
        // "23895781004888589149129578100458914450004504500000869687900450",
        // "238957810045891491295999781004589144500045040906785000450",
        // "2389578100458914912957810045890978007890236894145256345643561445000450",
      ];

      for (let index = 0; index < randomNumbers.length; index++) {
        let randomNumber = randomNumbers[index];
        await basicNFT.safeMint(owner.address, randomNumber, `Token ${index}`);
        let tokenId = index;
        const nftJSON = await basicNFT.getNFTDetails(tokenId);

        console.log(nftJSON);

        const TRAITS_INDEX = 3;
        const TRAIT_TYPE_INDEX = 0;
        const TRAIT_KEY_INDEX = 1;
        const TRAIT_VALUE_INDEX = 2;
        let nftTraits = nftJSON[TRAITS_INDEX];
        let attributes = [];

        for (let i = 0; i < nftTraits.length; i++) {
          let traitType = nftTraits[i][TRAIT_TYPE_INDEX];
          let traitKey = nftTraits[i][TRAIT_KEY_INDEX];
          let traitValue = nftTraits[i][TRAIT_VALUE_INDEX];

          console.log(traitValue);

          let traitLabel = await basicNFT.getTraitLabel(traitKey);

          let attribute = {
            trait_type: traitLabel,
            value:
              traitType == 1
                ? traitValue
                : await basicNFT.getTraitOptionsLabel(traitKey, traitValue),
            image: await genesisCollection.getTraitOptionImage(
              traitKey,
              traitValue
            ),
          };
          attributes.push(attribute);
        }

        // for (let i = 0; i < nftJSON.attributes.length; i++) {
        //   let attr = await basicNFT.getAttrLabel(
        //     tokenId,
        //     nftJSON.attributes[i].key,
        //     nftJSON.attributes[i].value
        //   );
        //   let attribute = {
        //     trait_type: attr.atrLabel,
        //     value:
        //       nftJSON.attributes[i].attributeType == 1
        //         ? attr.attrNumberValue
        //         : attr.atrValue,

        //     gene: nftJSON.attributes[i].gene,
        //     geneRarity: nftJSON.attributes[i].rarityGene,
        //     geneLength: nftJSON.attributes[i].geneLength,
        //   };
        //   attributes.push(attribute);
        // }
        console.log(attributes);
      }
      // expect(
      //   attributes[0].value,
      //   "Strength with gene 0450 should have yeld 46"
      // ).to.equal(46);
    });
  });

  //   describe("Total tokens", function () {
  //     it("Should have some tokens", async function () {
  //       const { genesisCollection, basicNFT, owner } = await deployContracts();

  //       await basicNFT.safeMint(
  //         owner.address,
  //         genesisCollection.target,
  //         125125123451234,
  //         `Token ${0}`
  //       );
  //       let count = await basicNFT.balanceOf(owner.address);
  //       console.log(`${owner.address} has ${count} tokens`);
  //     });
  //   });
});

async function setupCharacterAttributes(genesisCollectionInstance) {
  let armsPinkSVG =
    "<g class='monster-left-arm'> <path id='Shape' d='M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z' transform='translate(-114.73)' style='fill: #df4d60' /></g><g class='monster-right-arm'> <path id='Shape-2' data-name='Shape' d='M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z' transform='translate(-114.73)' style='fill: #df4d60' /></g>";
  // Numerical attributes with rarity
  await genesisCollectionInstance.addNumberTrait("Strength", 100, 0, 100);

  // Categorical attributes with respective rarities for each category
  await genesisCollectionInstance.addOptionsWithImageTrait(
    "Arms",
    100,
    ["Pink", "Grey", "Yellow", "Red", "Blue"],
    [10, 20, 30, 20, 20],
    [armsPinkSVG, armsPinkSVG, armsPinkSVG, armsPinkSVG, armsPinkSVG]
  );

  // Categorical attributes with respective rarities for each category
  await genesisCollectionInstance.addOptionsTrait(
    "Weapon",
    100,
    ["Sword", "Axe", "Bow", "Spear", "Wand"],
    [10, 20, 30, 20, 20]
  );
}
