const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { vrf, priceFeed } = require("./XX_DeployConfig.json");

//npx hardhat ignition deploy ignition/modules/01_DeployInfrastructure.js --network fuji --reset
module.exports = buildModule("DeployInfrastructure", (m) => {
  //Infrastructure
  const nftRandomManager = m.contract("NFTRandomManager", [
    vrf.subId,
    vrf.coordinatorAddress,
    vrf.coordinatorKey,
  ]);

  //Infrastructure
  const nftManager = m.contract("NFTManager", [priceFeed.AvaxUSD]);

  //Add Consumer to VRF coordinator
  // const coordinator = m.contractAt(
  //   "VRFCoordinatorV2Impl",
  //   VRF_COORDINATOR_ADDRESS
  // );
  // m.call(coordinator, "addConsumer", [VRF_SUBSCRIPTION_ID, genesisGenerator]);

  return { nftRandomManager, nftManager };
});
