const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const {
  functions,
  roles,
  admins,
  deployerAddress,
} = require("./resources/Configurations.json");
const fs = require("fs");
const path = require("path");

//npx hardhat ignition deploy ignition/modules/SurfForecastService.js --network fuji --reset
module.exports = buildModule("SurfForecastService", (m) => {
  const surfForecastService = m.contract("SurfForecastService", [
    functions.routerAddress,
  ]);

  m.call(surfForecastService, "grantRole", [
    roles.surfForecastConsumer,
    deployerAddress,
  ]);

  // Initialize functions settings
  const source = fs
    .readFileSync(
      path.resolve(__dirname, "resources/SurfForecastService_Source.js")
    )
    .toString();

  m.call(surfForecastService, "setForecastServiceConfig", [
    source,
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
