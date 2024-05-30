const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const surfGameModule = require("./SurfGame.js");
const {
  automation,
  surfGameConfig,
} = require("./resources/Configurations.json");

//npx hardhat ignition deploy ignition/modules/GameSetup.js --network fuji
module.exports = buildModule("GameSetup", (m) => {
  const { surfGame } = m.useModule(surfGameModule);

  //Set collections
  m.call(surfGame, "setSurfGameAddresses", [
    surfGameConfig.surferCollectionAddress,
    surfGameConfig.surfboardCollectionAddress,
  ]);

  m.call(surfGame, "setRunGameForwarderAddress", [automation.runGameForwarder]);
  m.call(surfGame, "setWaveUpdateForwarderAddress", [
    automation.setWaveForwarder,
  ]);

  return { surfGame };
});
