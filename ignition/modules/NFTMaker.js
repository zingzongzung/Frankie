const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("NFTMaker", (m) => {
  const owner = m.getAccount(0);

  const genesisCollection = m.contract("GenesisCollection");
  m.call(genesisCollection, "addOptionsTrait", [
    "Weapon",
    100,
    ["Sword", "Axe", "Bow", "Spear", "Wand"],
    [10, 20, 30, 20, 20],
  ]);

  const nftRandomManager = m.contract("NFTRandomManager", [
    102761256951729251622611869208045561216316510083631726135335465997162857706018n,
  ]);

  const basicNFT = m.contract("BasicNFT", [
    owner,
    genesisCollection,
    nftRandomManager,
  ]);

  return { genesisCollection, basicNFT };
});
