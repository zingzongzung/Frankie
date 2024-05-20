const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const surfGameModule = require("./SurfGame.js");

//npx hardhat ignition deploy ignition/modules/AllModules.js --network fuji --reset
module.exports = buildModule("Games", (m) => {
  const { surfGame } = m.useModule(surfGameModule);

  return { surfGame };
});
