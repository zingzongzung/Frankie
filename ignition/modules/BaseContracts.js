const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const passesModule = require("./Passes.js");
const shopManagerModule = require("./ShopManager.js");

//npx hardhat ignition deploy ignition/modules/BaseContracts.js --network fuji --reset
module.exports = buildModule("BaseContracts", (m) => {
  const { passNFT } = m.useModule(passesModule);
  const { shopManager } = m.useModule(shopManagerModule);

  return { passNFT, shopManager };
});
