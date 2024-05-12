const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { functions, roles, admins } = require("./Configurations.json");

//npx hardhat ignition deploy ignition/modules/SurfForecastService.js --network fuji --reset
module.exports = buildModule("SurfForecastService", (m) => {
  const surfForecastService = m.contract("SurfForecastService", [
    functions.routerAddress,
  ]);

  admins.forEach((adminAddress, i) => {
    //Grant Admin Roles
    m.call(
      surfForecastService,
      "grantRole",
      [roles.defaultAdmin, adminAddress],
      {
        id: `grantRole_Admin${i}`,
      }
    );
  });
  const data = ethers.toUtf8Bytes(functions.encryptedSecretsUrls);

  m.call(surfForecastService, "setForecastServiceConfig", [
    functions.source,
    data,
    functions.gasLimit,
    ethers.encodeBytes32String(functions.donName),
    functions.subscriptionId,
  ]);

  // const coordinator = m.contractAt(
  //   "FunctionsRouterInterface",
  //   functions.routerAddress
  // );
  // m.call(coordinator, "addConsumer", [
  //   functions.subscriptionId,
  //   surfForecastService,
  // ]);

  return { surfForecastService };
});
