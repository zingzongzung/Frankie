const {} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");

//npx hardhat test ./test/genesisNFT.js
describe("NFT collectionGenerator", function () {
  async function deployContracts() {
    const [owner, otherAccount] = await ethers.getSigners();

    // console.log(await collectionGenerator.NFT_MANAGER());
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

    /** The following deploys should be made everytime a new collection is created */
    //Deploy the collection
    const Collection = await ethers.getContractFactory("Collection");
    const collection = await Collection.deploy();

    //Deploy the NFT
    const CollectionGenerator = await ethers.getContractFactory(
      "CollectionGenerator"
    );
    const collectionGenerator = await CollectionGenerator.deploy(
      collection.target,
      nftRandomManager.target,
      "localhost",
      "NFT Name",
      "GGGG"
    );

    //Give our newly deployed nft permissions to call nft random manager
    await nftRandomManager.grantRole(
      NFT_RANDOM_MANAGER_ROLE,
      collectionGenerator.target
    );

    //Specify on our newly deployed nft who can mint
    await collectionGenerator.grantRole(NFT_MANAGER, shopManager.target);

    //Specify on our newly deployed nft who can mint
    await collectionGenerator.grantRole(
      NFT_RANDOM_MANAGER_ROLE,
      nftRandomManager.target
    );

    //Add the collection to the list of managed collections on our nft manager
    await shopManager.addManagedCollection(collectionGenerator.target);

    //Initialize genesis Colection traits
    await setupCharacterAttributes(collection);

    return {
      collection,
      collectionGenerator,
      owner,
      shopManager,
      mockCoordinator,
      nftRandomManager,
    };
  }

  describe("Test an instance of a Collection NFT - GenesisNFT", function () {
    it("Shop and get item with genes 23895781004589149129578100458914450004567867867856785990002450", async function () {
      const {
        collection,
        collectionGenerator,
        owner,
        shopManager,
        mockCoordinator,
        nftRandomManager,
      } = await deployContracts();

      const result = await shopManager.getCollectionPrice(
        collectionGenerator.target
      );
      // console.log(result); // divide by 10**18 to get the AVAX Value

      await shopManager.mintNFT(collectionGenerator.target, `Token `, {
        value: ethers.parseEther("0.9999"),
      });

      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [23895781004589149129578100458914450004567867867856785990002450n]
      );

      const nftJSON = await collectionGenerator.getNFTDetails(0);
      const nftJSONString = JSON.stringify(nftJSON, (key, value) =>
        typeof value === "bigint" ? value.toString() : value
      );
      999471054260n;

      expect(
        nftJSONString,
        "Attributes for gene should have strenght 100 and arms blue and weapon and"
      ).to.equal(
        '["Token ","23895781004589149129578100458914450004567867867856785990002450","0",["50","0","78","78"],[["1","11",true,"24"],["1","12",true,"94"],["2","13",true,"2"],["0","15",true,"4"]]]'
      );
    });
  });

  it("Shop at price 0 without sending any value", async function () {
    const {
      collection,
      collectionGenerator,
      owner,
      shopManager,
      mockCoordinator,
      nftRandomManager,
    } = await deployContracts();

    await collection.setCollectionAttributes(0, 0, 0);
    const result = await shopManager.getCollectionPrice(
      collectionGenerator.target
    );
    console.log(result); // divide by 10**18 to get the AVAX Value

    await shopManager.mintNFT(collectionGenerator.target, `Token `);

    await mockCoordinator.mockVRFCoordinatorResponse(nftRandomManager.target, [
      23895781004589149129578100458914450004567867867856785990002450n,
    ]);

    const nftJSON = await collectionGenerator.getNFTDetails(0);
    const nftJSONString = JSON.stringify(nftJSON, (key, value) =>
      typeof value === "bigint" ? value.toString() : value
    );
    999471054260n;

    expect(
      nftJSONString,
      "Attributes for gene should have strenght 100 and arms blue and weapon and"
    ).to.equal(
      '["Token ","23895781004589149129578100458914450004567867867856785990002450","0",["50","0","78","78"],[["1","11",true,"24"],["1","12",true,"94"],["2","13",true,"2"],["0","15",true,"4"]]]'
    );
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
