const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { roles } = require("./Configurations.json");
const randomManagerModule = require("./RandomManager.js");
const passManagerModule = require("./PassManager.js");

//npx hardhat ignition deploy ignition/modules/Passes.js --network fuji --reset
module.exports = buildModule("Passes", (m) => {
  const { nftRandomManager } = m.useModule(randomManagerModule);
  const { passManager } = m.useModule(passManagerModule);

  //Define Pass Configuration
  const passConfig = m.contract("PassConfig");

  //Add collection Name
  //Add collection Address
  m.call(passConfig, "setCollectionAttributes", [0, 100, 100]);

  //Define Pass NFT
  const passNFT = m.contract(
    "CollectionNFT",
    [
      passConfig,
      nftRandomManager,
      "https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/rest/Token",
      "NFT Forge Pass",
      "NFP",
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

  m.call(passManager, "mintNFT", [passNFT, "Pass 1"]);
  m.call(passManager, "mintNFT", [passNFT, "Pass 2"], {
    id: "mintAnotherPass",
  });

  return { passNFT };
});
