const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const {
  functions,
  roles,
  admins,
  deployerAddress,
} = require("./Configurations.json");

//npx hardhat ignition deploy ignition/modules/SurfForecastService.js --network fuji --reset
module.exports = buildModule("SurfForecastService", (m) => {
  const surfForecastService = m.contract("SurfForecastService", [
    functions.routerAddress,
  ]);

  m.call(surfForecastService, "grantRole", [
    roles.surfForecastConsumer,
    deployerAddress,
  ]);

  // admins.forEach((adminAddress, i) => {
  //   //Grant Admin Roles
  //   m.call(
  //     surfForecastService,
  //     "grantRole",
  //     [roles.defaultAdmin, adminAddress],
  //     {
  //       id: `grantRole_Admin${i}`,
  //     }
  //   );
  // });

  m.call(surfForecastService, "setForecastServiceConfig", [
    functions.source,
    ethers.hexlify(functions.encryptedSecretsUrls),
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
