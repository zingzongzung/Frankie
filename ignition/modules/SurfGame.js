const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const {
  functions,
  roles,
  admins,
  deployerAddress,
} = require("./resources/Configurations.json");
const randomManagerModule = require("./RandomManager");
const surfForecastServiceModule = require("./SurfForecastService");

//npx hardhat ignition deploy ignition/modules/SurfGame.js --network fuji --reset
module.exports = buildModule("SurfGame", (m) => {
  const { nftRandomManager } = m.useModule(randomManagerModule);
  const { surfForecastService } = m.useModule(surfForecastServiceModule);

  const surfGame = m.contract("SurfGame", [
    nftRandomManager,
    surfForecastService,
  ]);

  //Surf Forecast Service
  m.call(surfForecastService, "grantRole", [
    roles.surfForecastConsumer,
    surfGame,
  ]);

  //Pass Manager - Random Roles
  m.call(nftRandomManager, "grantRole", [roles.randomManager, surfGame], {
    id: "grantRole_randomManager_on_nftRandomManager_to_SurfGame",
  });
  m.call(surfGame, "grantRole", [roles.randomManager, nftRandomManager], {
    id: "grantRole_randomManager_on_cSurfGame_to_nftRandomManager",
  });

  return { surfForecastService };
});
