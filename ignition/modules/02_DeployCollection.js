const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const deployInfrastructure = require("./01_DeployInfrastructure.js");

//npx hardhat ignition deploy ignition/modules/02_DeployCollection.js --network fuji
module.exports = buildModule("DeployCollection", (m) => {
  const { nftRandomManager, nftManager } = m.useModule(deployInfrastructure);

  //Prepare a collection
  const genesisCollection = m.contract("GenesisCollection");
  let armsExampleSVG =
    "<g class='monster-left-arm'> <path id='Shape' d='M200.78,257.08s-51.7,3.15-81.17,62.67a40,40,0,0,0,.71,39.55c10.43,16.16,35.17,24.25,94.31-38.9Z' transform='translate(-114.73)' style='fill: #df4d60' /></g><g class='monster-right-arm'> <path id='Shape-2' data-name='Shape' d='M311.22,257.08c0,.05,51.71,3.17,81.21,62.67a40,40,0,0,1-.71,39.55c-10.17,15.77-34,23.83-90-34.43Z' transform='translate(-114.73)' style='fill: #df4d60' /></g>";
  m.call(genesisCollection, "addOptionsTrait", [
    15,
    "Weapon",
    100,
    ["Sword", "Axe", "Bow", "Spear", "Wand"],
    [10, 20, 30, 20, 20],
  ]);
  m.call(genesisCollection, "addOptionsWithImageTrait", [
    16,
    "Arms",
    100,
    ["Pink", "Grey", "Yellow", "Red", "Blue"],
    [10, 20, 30, 20, 20],
    [
      armsExampleSVG,
      armsExampleSVG,
      armsExampleSVG,
      armsExampleSVG,
      armsExampleSVG,
    ],
  ]);
  m.call(genesisCollection, "addNumberTrait", [16, "Strength", 100, 0, 100]);

  //Deploy a contract pointing to the newly created collection
  const genesisGenerator = m.contract("GenesisGenerator", [
    genesisCollection,
    nftRandomManager,
    "https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API",
    "FromJS",
    "PGN",
  ]);

  return { nftRandomManager, nftManager, genesisCollection, genesisGenerator };
});
