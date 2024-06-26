const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { roles } = require("./resources/Configurations.json");
const randomManagerModule = require("./RandomManager.js");
const passManagerModule = require("./PassManager.js");

//npx hardhat ignition deploy ignition/modules/Passes.js --network fuji --reset
const SetPassConfigModule = buildModule("SetPassConfig", (m) => {
  //Define Pass Configuration
  const passConfig = m.contract("PassConfig");
  m.call(passConfig, "setCollectionAttributes", [1000, 1024, 1024]);

  return { passConfig };
});

module.exports = buildModule("Passes", (m) => {
  const { passConfig } = m.useModule(SetPassConfigModule);
  const { nftRandomManager } = m.useModule(randomManagerModule);
  const { passManager } = m.useModule(passManagerModule);

  m.call(passConfig, "closeCollection");

  //Define Pass NFT
  const passNFT = m.contract(
    "CollectionNFT",
    [
      passConfig,
      nftRandomManager,
      "https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/rest/Token",
      "Frankie Pass",
      "NFP",
      roles.defaultAdmin, //Just needed to pass an empty bytes value
    ],
    {
      id: "PassNFT",
    }
  );

  m.call(passManager, "addManagedCollection", [passNFT]);
  m.call(passNFT, "grantRole", [roles.nftManager, passManager], {
    id: "grantRole_NftManager_on_PassNFT_to_passManager",
  });

  //Pass Manager - Random Roles
  m.call(nftRandomManager, "grantRole", [roles.randomManager, passNFT], {
    id: "grantRole_randomManager_on_nftRandomManager_to_passNFT",
  });
  m.call(passNFT, "grantRole", [roles.randomManager, nftRandomManager], {
    id: "grantRole_randomManager_on_PassNFT_to_nftRandomManager",
  });

  //m.call(passManager, "mintNFT", [passNFT, "Pass 1"]);
  // m.call(passManager, "mintNFT", [passNFT, "Pass 2"], {
  //   id: "mintAnotherPass",
  // });

  return { passNFT };
});
