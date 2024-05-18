const {} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { ethers } = require("hardhat");

const passNFTName = "Pass NFT";

/**
 *
 * Deploys the base contracts for the product
 *
 * @returns the base contracts for the product
 */
async function deployContractsInfrastructure() {
  const [owner, otherAccount] = await ethers.getSigners();

  //Deploy Mock Contracts for VRF
  const MockCoordinator = await ethers.getContractFactory("MockCoordinator");
  const mockCoordinator = await MockCoordinator.deploy();
  const MockAggregatorAVAX_USD = await ethers.getContractFactory(
    "MockAggregatorAVAX_USD"
  );
  const mockAggregatorAVAX_USD = await MockAggregatorAVAX_USD.deploy();

  const NFTRandomManager = await ethers.getContractFactory("NFTRandomManager");
  const nftRandomManager = await NFTRandomManager.deploy(
    /* VRF Subscription Id */ 5,
    mockCoordinator.target,
    "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61" //Key Hash
  );

  //Deploy the nft manager, it will be responsible to know which collections were created and to "shop"
  const ShopManager = await ethers.getContractFactory("ShopManager");
  const shopManager = await ShopManager.deploy(mockAggregatorAVAX_USD.target);

  //Deploy the game manager,
  const GameManager = await ethers.getContractFactory("GameManager");
  const gameManager = await GameManager.deploy();

  //Deploy the pass manager,
  const PassManager = await ethers.getContractFactory("PassManager");
  const passManager = await PassManager.deploy(mockAggregatorAVAX_USD.target);

  //Deploy the pass configuration and nft
  const PassConfigFactory = await ethers.getContractFactory("PassConfig");
  const passConfig = await PassConfigFactory.deploy();
  await passConfig.setCollectionAttributes(0, 0, 0);

  const PassNFTFactory = await ethers.getContractFactory("CollectionNFT");
  const passNFT = await PassNFTFactory.deploy(
    passConfig.target,
    nftRandomManager.target,
    "localhost",
    passNFTName,
    "Pass",
    new Uint8Array()
  );

  //Grant necessary permissions to the pass manager to our new pass
  await addManagedCollectionToNFTManager(passManager, passNFT);
  await grantRandomManagerRoles(nftRandomManager, passNFT);

  const simulateMockResponse = async (responses) => {
    let simulatedResponses = responses || [
      23895781004589149129578100458914450004567867867856785990002450n,
    ];
    await mockCoordinator.mockVRFCoordinatorResponse(
      nftRandomManager.target,
      simulatedResponses
    );
  };

  return {
    nftRandomManager,
    shopManager,
    gameManager,
    passManager,
    passConfig,
    passNFT,
    simulateMockResponse,
  };
}

/**
 *
 * Grants necessary random roles
 *
 * @param randomManager Must be a deployed random manager
 * @param  targetContract  Must be a deployed Collection nft
 */
async function grantRandomManagerRoles(randomManager, targetContract) {
  const NFT_RANDOM_MANAGER_ROLE =
    "0xba97d1e7c7cac970a86143e4a79d94ccf81090bb6c8dfb9571552cb2226d115c";
  await randomManager.grantRole(NFT_RANDOM_MANAGER_ROLE, targetContract.target);
  await targetContract.grantRole(NFT_RANDOM_MANAGER_ROLE, randomManager.target);
}

/**
 *
 * Grants necessary random roles
 *
 * @param randomManager Must be a deployed random manager
 * @param  targetContract  Must be a deployed Collection nft
 */
async function grantSurfConsumerRoles(randomManager, targetContract) {
  const NFT_SURF_FORECAST_SERVICE_ROLE =
    "0x8794dbefcad8d057429a8e6212647fab37fefb070924aa9c4fd35ba03144892b";
  await randomManager.grantRole(
    NFT_SURF_FORECAST_SERVICE_ROLE,
    targetContract.target
  );
  await targetContract.grantRole(
    NFT_SURF_FORECAST_SERVICE_ROLE,
    randomManager.target
  );
}

/**
 *
 * Add managed collection to nft manager
 *
 * @param nftManager
 * @param targetCollection
 */
async function addManagedCollectionToNFTManager(nftManager, targetCollection) {
  const NFT_MANAGER =
    "0x8972b9d3322325818f1215107c5cad20b0d1bd8a19dd8c3113a4cda650cdfe63";

  await nftManager.addManagedCollection(targetCollection.target);
  await targetCollection.grantRole(NFT_MANAGER, nftManager.target);
}

async function signANumberAndAbytes32(signer, aNumber, aBytes32) {
  const messageConcatenated = ethers.solidityPacked(
    ["uint256", "bytes32"],
    [aNumber, aBytes32]
  );

  const messageToSign = ethers.keccak256(messageConcatenated);

  // const messageToSign = ethers.solidityPackedKeccak256(
  //   ["uint256", "bytes32"],
  //   [aNumber, aBytes32]
  // );

  let value = [];
  for (let i = 2; i < messageToSign.length; i = i + 2) {
    let current = "0x" + messageToSign.substring(i, i + 2);
    value.push(current);
  }

  const messageSigned = await signer.signMessage(new Uint8Array(value));

  // console.log(new Uint8Array(value));

  // console.log(messageConcatenated);
  // console.log(messageToSign);
  // console.log(messageSigned);
  return messageSigned;
}

/**
 *
 * Deploys a collection
 *
 * @param {*} collectionName
 * @param {*} addTraitsToCollectionFunction
 * @param {*} nftRandomManager
 * @param {*} shopManager
 * @param {*} gameManager
 * @param {*} passManager
 * @param {*} passConfig
 * @param {*} passNFT
 * @returns
 */
async function deployCollection(
  passId,
  collectionName,
  addTraitsToCollectionFunction,
  nftRandomManager,
  shopManager,
  gameManager,
  passManager,
  passNFT
) {
  const [owner] = await ethers.getSigners();

  //Mint a pass for owner
  await passManager.mintNFT(passNFT.target, "Pass 1");

  const collectionNameBytes32 = stringToBytes32(collectionName);
  const signature = await signANumberAndAbytes32(
    owner,
    passId,
    collectionNameBytes32
  );

  //Deploy the collection
  const CollectionConfigFactory = await ethers.getContractFactory(
    "CollectionConfig"
  );
  const collection = await CollectionConfigFactory.deploy(
    passManager.target,
    passNFT.target,
    passId,
    signature,
    collectionNameBytes32
  );

  //Runs the function to add Traits on collection
  addTraitsToCollectionFunction && addTraitsToCollectionFunction(collection);

  //Deploy the NFT
  const CollectionNFTFactory = await ethers.getContractFactory("CollectionNFT");
  const collectionNFT = await CollectionNFTFactory.deploy(
    collection.target,
    nftRandomManager.target,
    "localhost",
    collectionName,
    "GGGG",
    signature
  );

  //Grant necessary permissions to use the random manager
  await grantRandomManagerRoles(nftRandomManager, collectionNFT);

  //Grant necessary permissions to the shop to our new collection
  await addManagedCollectionToNFTManager(shopManager, collectionNFT);
  await addManagedCollectionToNFTManager(gameManager, collectionNFT);

  return {
    collection,
    collectionNFT,
    CollectionConfigFactory,
  };
}

function stringToBytes32(text) {
  // Check if the string is longer than 32 bytes and truncate if necessary
  if (ethers.toUtf8Bytes(text).length > 32) {
    throw new Error("String too long");
  }
  return ethers.encodeBytes32String(text);
}

function bytes32ToString(bytes) {
  return ethers.decodeBytes32String(bytes);
}

module.exports = {
  deployContractsInfrastructure,
  grantRandomManagerRoles,
  addManagedCollectionToNFTManager,
  deployCollection,
  stringToBytes32,
  bytes32ToString,
  grantSurfConsumerRoles,
};
