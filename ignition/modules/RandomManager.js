const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { vrf, roles, admins } = require("./Configurations.json");

//npx hardhat ignition deploy ignition/modules/01_DeployInfrastructure.js --network fuji --reset
module.exports = buildModule("RandomManager", (m) => {
  const nftRandomManager = m.contract("NFTRandomManager", [
    vrf.subId,
    vrf.coordinatorAddress,
    vrf.coordinatorKey,
  ]);

  admins.forEach((adminAddress, i) => {
    //Grant Admin Roles
    m.call(nftRandomManager, "grantRole", [roles.defaultAdmin, adminAddress], {
      id: `grantRole_Admin${i}`,
    });
  });

  //
  //Add Consumer to VRF coordinator
  // const coordinator = m.contractAt(
  //   "VRFCoordinatorV2Impl",
  //   VRF_COORDINATOR_ADDRESS
  // );
  // m.call(coordinator, "addConsumer", [VRF_SUBSCRIPTION_ID, genesisGenerator]);

  return { nftRandomManager };
});
