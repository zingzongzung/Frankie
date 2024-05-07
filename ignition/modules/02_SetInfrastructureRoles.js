const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { roles } = require("./XX_DeployConfig.json");
const infrastructure = require("./01_DeployInfrastructure.js");

//npx hardhat ignition deploy ignition/modules/02_SetInfrastructureRoles.js --network fuji
module.exports = buildModule("SetInfrastructureRoles", (m) => {
  const { nftRandomManager, shopManager, passNFT, passManager } =
    m.useModule(infrastructure);

  //Pass Manager - Managed Collecions
  m.call(passManager, "addManagedCollection", [passNFT]);
  m.call(passNFT, "grantRole", [roles.nftManager, passManager], {
    id: "grantRole_nftManager_to_passManager",
  });

  //Pass Manager - Random Roles
  m.call(nftRandomManager, "grantRole", [roles.randomManager, passNFT], {
    id: "grantRole_randomManager_to_passNFT",
  });
  m.call(passNFT, "grantRole", [roles.randomManager, nftRandomManager], {
    id: "grantRole_randomManager_to_nftRandomManager",
  });

  //Grant Admin Roles
  m.call(
    nftRandomManager,
    "grantRole",
    [roles.defaultAdmin, "0x30ed1a5FB009d6B68EEf3099239727604541bAd4"],
    {
      id: "grantRole_AdminRole_OnRandomManager_ToServerWallet",
    }
  );

  m.call(
    shopManager,
    "grantRole",
    [roles.defaultAdmin, "0x30ed1a5FB009d6B68EEf3099239727604541bAd4"],
    {
      id: "grantRole_AdminRole_onShopManager_ToServerWallet",
    }
  );

  m.call(passManager, "mintNFT", [passNFT, "Pass 1"]);

  //
  //Add Consumer to VRF coordinator
  // const coordinator = m.contractAt(
  //   "VRFCoordinatorV2Impl",
  //   VRF_COORDINATOR_ADDRESS
  // );
  // m.call(coordinator, "addConsumer", [VRF_SUBSCRIPTION_ID, genesisGenerator]);

  return { nftRandomManager, shopManager, passNFT, passManager };
});
