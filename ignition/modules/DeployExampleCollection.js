const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

//npx hardhat ignition deploy ignition/modules/DeployExampleCollection.js --network fuji --reset
module.exports = buildModule("DeployExampleCollection", (m) => {
  const owner = m.getAccount(0);
  const NFT_RANDOM_MANAGER_ROLE =
    "0xba97d1e7c7cac970a86143e4a79d94ccf81090bb6c8dfb9571552cb2226d115c";

  //Infrastructure
  const nftRandomManager = m.contract("NFTRandomManager", [1863]);

  //Prepare a collection
  const genesisCollection = m.contract("GenesisCollection");
  m.call(genesisCollection, "addOptionsTrait", [
    15,
    "Weapon",
    100,
    ["Sword", "Axe", "Bow", "Spear", "Wand"],
    [10, 20, 30, 20, 20],
  ]);

  //Deploy a contract pointing to the newly created collection
  const basicNFT = m.contract("BasicNFT", [
    owner,
    genesisCollection,
    nftRandomManager,
  ]);

  m.call(basicNFT, "setTokenURIBaseURL", [
    "https://personal-ixqe4210.outsystemscloud.com/tokenURI",
  ]);

  //Grant accesses to the new contract to Forge Managers
  m.call(nftRandomManager, "grantRole", [NFT_RANDOM_MANAGER_ROLE, basicNFT]);

  return { nftRandomManager, genesisCollection, basicNFT };
});
