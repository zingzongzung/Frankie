const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { roles } = require("./resources/Configurations.json");
const passesModule = require("./Passes.js");
const shopManagerModule = require("./ShopManager.js");
const surfGameModule = require("./SurfGame.js");

//npx hardhat ignition deploy ignition/modules/AllModules.js --network fuji --reset
module.exports = buildModule("AllModules", (m) => {
  const { passNFT } = m.useModule(passesModule);
  const { shopManager } = m.useModule(shopManagerModule);
  const { surfGame } = m.useModule(surfGameModule);

  return { passNFT, shopManager, surfGame };
});
