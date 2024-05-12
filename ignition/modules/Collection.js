const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { roles } = require("./Configurations.json");
const shopManagerModule = require("./ShopManager.js");
const randomManagerModule = require("./RandomManager.js");
const passManagerModule = require("./PassManager.js");
const passModule = require("./Passes.js");

//npx hardhat ignition deploy ignition/modules/Collection.js --network fuji --reset
module.exports = buildModule("SampleCollection", (m) => {
  //const [owner, otherAccount] = ethers.getSigners();
  const { shopManager } = m.useModule(shopManagerModule);
  const { nftRandomManager } = m.useModule(randomManagerModule);
  const { passManager } = m.useModule(passManagerModule);
  const { passNFT } = m.useModule(passModule);
  // console.log(owner);
  const TEST_MESSAGE = "Example";
  const hashedMessage =
    "0x500aff74b3dc30439234425c0759c798a9b6350ca7c1636be525b97af22b8fca";
  const signature =
    "0xb1aadf0e9d8754156b1fdbc9a1438e26b68f1529cf4e859b9c1c45cd2fe9739665bd9a68694f50ec025e784d38d059022b46608c0954d1082098f43bc1d9c7bf1c"; //owner.signMessage(TEST_MESSAGE);

  //Define Pass Configuration
  const collectionConfig = m.contract(
    "CollectionConfig",
    [
      passManager,
      passNFT,
      0,
      hashedMessage,
      signature,
      stringToBytes32("Teste"),
    ],
    {
      id: "CollectionConfig_FromPass9",
    }
  );

  //Add collection Name
  //Add collection Address
  m.call(collectionConfig, "setCollectionAttributes", [0, 100, 100]);

  //Define Pass NFT
  const collectionNFT = m.contract(
    "CollectionNFT",
    [
      collectionConfig,
      nftRandomManager,
      "https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/rest/Token",
      "A Sample Collection",
      "NFP",
    ],
    {
      id: "CollectionNFT_FromPassNFT",
    }
  );

  m.call(shopManager, "addManagedCollection", [collectionNFT]);
  m.call(collectionNFT, "grantRole", [roles.nftManager, shopManager], {
    id: "grantRole_NftManager_on_collectionNFT_to_shopManager",
  });

  //Pass Manager - Random Roles
  m.call(nftRandomManager, "grantRole", [roles.randomManager, collectionNFT], {
    id: "grantRole_randomManager_on_nftRandomManager_to_collectionNFT",
  });
  m.call(collectionNFT, "grantRole", [roles.randomManager, nftRandomManager], {
    id: "grantRole_randomManager_on_collectionNFT_to_nftRandomManager",
  });

  // m.call(passManager, "mintNFT", [passNFT, "Pass 1"]);
  m.call(shopManager, "mintNFT", [collectionNFT, "From JS"]);

  return { collectionNFT };
});

function stringToBytes32(text) {
  // Check if the string is longer than 32 bytes and truncate if necessary
  if (ethers.toUtf8Bytes(text).length > 32) {
    throw new Error("String too long");
  }
  return ethers.encodeBytes32String(text);
}
