const {} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

//npx hardhat test ./test/genesisNFT.js
describe("NFT collectionNFT", function () {
  async function deployContracts() {
    const [owner, otherAccount] = await ethers.getSigners();

    //console.log(await collectionNFT.NFT_MANAGER());
    const NFT_RANDOM_MANAGER_ROLE =
      "0xba97d1e7c7cac970a86143e4a79d94ccf81090bb6c8dfb9571552cb2226d115c";

    const NFT_MANAGER =
      "0x8972b9d3322325818f1215107c5cad20b0d1bd8a19dd8c3113a4cda650cdfe63";

    /** The following deploys should be made only once */
    //Deploy Mock Coordinator, this will help us simulate a call to the VRF Chainlink
    //Use this address instead when instantiating the random manager
    const MockCoordinator = await ethers.getContractFactory("MockCoordinator");
    const mockCoordinator = await MockCoordinator.deploy();
    const MockAggregatorAVAX_USD = await ethers.getContractFactory(
      "MockAggregatorAVAX_USD"
    );
    const mockAggregatorAVAX_USD = await MockAggregatorAVAX_USD.deploy();

    const NFTRandomManager = await ethers.getContractFactory(
      "NFTRandomManager"
    );
    const nftRandomManager = await NFTRandomManager.deploy(
      /* VRF Subscription Id */ 5,
      mockCoordinator.target,
      "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61" //Key Hash
    );

    //Deploy the nft manager, it will be responsible to know which collections were created and to "shop"
    const ShopManager = await ethers.getContractFactory("ShopManager");
    const shopManager = await ShopManager.deploy(mockAggregatorAVAX_USD.target);

    //Deploy the pass configuration,
    const PassConfigFactory = await ethers.getContractFactory("PassConfig");
    const passConfig = await PassConfigFactory.deploy();

    //Deploy the game manager,
    const GameManager = await ethers.getContractFactory("GameManager");
    const gameManager = await GameManager.deploy();

    //Deploy the pass manager,
    const PassManager = await ethers.getContractFactory("PassManager");
    const passManager = await PassManager.deploy(mockAggregatorAVAX_USD.target);

    //Prepare a Pass and mint one for the user
    //Deploy the NFT
    const PassNFTFactory = await ethers.getContractFactory("CollectionNFT");
    const passNFT = await PassNFTFactory.deploy(
      passConfig.target,
      nftRandomManager.target,
      "localhost",
      "Pass NFT",
      "Pass"
    );
    //Grant necessary permissions to the pass manager to our new pass
    await passManager.addManagedCollection(passNFT.target);
    await passNFT.grantRole(NFT_MANAGER, passManager.target);

    //Grant random consumer permissions to the pass
    //Grant necessary permissions to use the random manager
    await nftRandomManager.grantRole(NFT_RANDOM_MANAGER_ROLE, passNFT.target);
    await passNFT.grantRole(NFT_RANDOM_MANAGER_ROLE, nftRandomManager.target);

    //mint a pass for this user
    await passManager.mintNFT(passNFT.target, "Pass 1");

    //For now we will generate a guid that will be sent both to the pass manager and to the server
    //In the future lets use the hash of the collection that the user is looking to
    //And then use it to verify the collection integrity in the end
    // Define a message
    let originalMessage = "Hello world";
    let signature = await owner.signMessage(originalMessage);

    console.log(signature);
    let signer = await passManager.testeGetSigner(originalMessage, signature);

    console.log(owner.address);
    console.log(signer);

    //Deploy the collection
    const CollectionConfigFactory = await ethers.getContractFactory(
      "CollectionConfig"
    );
    const collection = await CollectionConfigFactory.deploy(
      passManager.target,
      passNFT.target,
      0,
      originalMessage,
      signature
    );

    //Deploy the NFT
    const CollectionNFTFactory = await ethers.getContractFactory(
      "CollectionNFT"
    );
    const collectionNFT = await CollectionNFTFactory.deploy(
      collection.target,
      nftRandomManager.target,
      "localhost",
      "NFT Name",
      "GGGG"
    );

    //Grant necessary permissions to use the random manager
    await nftRandomManager.grantRole(
      NFT_RANDOM_MANAGER_ROLE,
      collectionNFT.target
    );
    await collectionNFT.grantRole(
      NFT_RANDOM_MANAGER_ROLE,
      nftRandomManager.target
    );

    //Grant necessary permissions to the shop to our new collection
    await shopManager.addManagedCollection(collectionNFT.target);
    await collectionNFT.grantRole(NFT_MANAGER, shopManager.target);

    //Grant necessary permissions to the game to our new collection
    await gameManager.addManagedCollection(collectionNFT.target);
    await collectionNFT.grantRole(NFT_MANAGER, gameManager.target);

    //Initialize genesis Colection traits
    await setupCharacterAttributes(collection);

    return {
      collection,
      collectionNFT,
      owner,
      shopManager,
      mockCoordinator,
      nftRandomManager,
      gameManager,
    };
  }

  describe("Test Forge", function () {
    it("Shop/mint  an item that costs more than 0", async function () {
      const {
        collection,
        collectionNFT,
        owner,
        shopManager,
        mockCoordinator,
        nftRandomManager,
        gameManager,
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
      ).to.equal(
        '["Token ","23895781004589149129578100458914450004567867867856785990002450","0",["50","0","78","78"],[["1","11",true,"24"],["1","12",true,"94"],["2","13",true,"2"],["0","15",true,"4"]]]'
      );
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
      ).to.equal(
        '["Token ","23895781004589149129578100458914450004567867867856785990002450","0",["50","0","78","78"],[["1","11",true,"24"],["1","12",true,"94"],["2","13",true,"2"],["0","15",true,"4"]]]'
      );

      //Rerol two traits
      await gameManager.rerollAttribute(collectionNFT, 0, 11);
      await gameManager.rerollAttribute(collectionNFT, 0, 13);

      nftJSON = await collectionNFT.getNFTDetails(0);
      nftJSONString = JSON.stringify(nftJSON, bigIntParser);
      //console.log(nftJSONString);

      expect(
        nftJSONString,
        "Attributes expected different from the generated ones after reroll"
      ).to.equal(
        '["Token ","23895781004589149129578100458914450004567867867856785990002450","0",["50","0","78","78"],[["1","11",true,"99"],["1","12",true,"94"],["2","13",true,"4"],["0","15",true,"4"]]]'
      );
    });

    it("Mint nft for free", async function () {
      const {
        collection,
        collectionNFT,
        owner,
        shopManager,
        mockCoordinator,
        nftRandomManager,
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
      ).to.equal(
        '["Token ","23895781004589149129578100458914450004567867867856785990002450","0",["50","0","78","78"],[["1","11",true,"24"],["1","12",true,"94"],["2","13",true,"2"],["0","15",true,"4"]]]'
      );
    });
  });
});

/**
 *
 * Define collection traits
 *
 */
async function setupCharacterAttributes(collectionInstance) {
  await collectionInstance.setCollectionAttributes(3350, 0, 0);

  let armsPinkSVG =
    "<g class='monster-left-arm'> <path id='Shape' d='M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z' transform='translate(-114.73)' style='fill: #df4d60' /></g><g class='monster-right-arm'> <path id='Shape-2' data-name='Shape' d='M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z' transform='translate(-114.73)' style='fill: #df4d60' /></g>";
  // Numerical attributes with rarity
  await collectionInstance.addNumberTrait(11, "Strength", 100, 0, 100);
  await collectionInstance.addNumberTrait(12, "Strengtsh", 1, 0, 100);

  // Categorical attributes with respective rarities for each category
  await collectionInstance.addOptionsWithImageTrait(
    13,
    "Arms",
    100,
    ["Pink", "Grey", "Yellow", "Red", "Blue"],
    [10, 20, 30, 20, 20],
    [armsPinkSVG, armsPinkSVG, armsPinkSVG, armsPinkSVG, armsPinkSVG]
  );

  await collectionInstance.addOptionsTrait(
    15,
    "Weapon",
    100,
    ["Sword", "Axe", "Bow", "Spear", "Wand"],
    [10, 20, 30, 20, 20]
  );
}

const bigIntParser = (key, value) => {
  return typeof value === "bigint" ? value.toString() : value;
};
