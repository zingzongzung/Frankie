const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { vrf, roles, admins } = require("./resources/Configurations.json");

//npx hardhat ignition deploy ignition/modules/RandomManager.js --network fuji --reset
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

  //Add Random manager to VRF
  const coordinator = m.contractAt(
    "VRFCoordinatorV2Interface",
    vrf.coordinatorAddress
  );
  m.call(coordinator, "addConsumer", [vrf.subId, nftRandomManager]);

  return { nftRandomManager };
});
