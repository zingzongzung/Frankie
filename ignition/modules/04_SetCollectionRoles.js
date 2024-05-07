const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { roles } = require("./XX_DeployConfig.json");
const deployCollection = require("./02_DeployCollection.js");

//npx hardhat ignition deploy ignition/modules/03_SetupPermissions.js --network fuji  --reset
module.exports = buildModule("SetupPermissions", (m) => {
  const { nftRandomManager, nftManager, genesisGenerator } =
    m.useModule(deployCollection);

  //Add collection to nft manager
  m.call(nftManager, "addManagedCollection", [genesisGenerator]);

  //Random manager to allow genesisGenerator to invoke random
  m.call(nftRandomManager, "grantRole", [
    roles.randomManager,
    genesisGenerator,
  ]);

  // //genesisGenerator to allow random manager to callback and complete mint
  m.call(genesisGenerator, "grantRole", [
    roles.randomManager,
    nftRandomManager,
  ]);

  // //genesisGenerator to allo shop manager to invoke safemint
  m.call(genesisGenerator, "grantRole", [roles.shopManager, nftManager], {
    id: "grantRole_2",
  });
  return { nftRandomManager, nftManager, genesisGenerator };
});
