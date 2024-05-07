const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { vrf, priceFeed } = require("./XX_DeployConfig.json");

//npx hardhat ignition deploy ignition/modules/01_DeployInfrastructure.js --network fuji --reset
module.exports = buildModule("DeployInfrastructure", (m) => {
  const nftRandomManager = m.contract("NFTRandomManager", [
    vrf.subId,
    vrf.coordinatorAddress,
    vrf.coordinatorKey,
  ]);

  const shopManager = m.contract("ShopManager", [priceFeed.AvaxUSD]);

  const passManager = m.contract("PassManager", [priceFeed.AvaxUSD]);

  const passConfig = m.contract("PassConfig");

  const svgPass =
    '<svg width="100" height="50" xmlns="http://www.w3.org/2000/svg"><rect x="10" y="10" width="80" height="30" fill="lightgray" stroke="black" stroke-width="2" rx="5" /><text x="30" y="30" font-family="Arial" font-size="12" fill="black">PASS</text></svg>';

  m.call(passConfig, "addOptionsWithImageTrait", [
    0,
    "Season",
    100,
    ["Genesis"],
    [100],
    [svgPass],
  ]);

  m.call(passConfig, "setCollectionAttributes", [50, 100, 100]);
  m.call(passConfig, "setCollectionAttributes", [0, 100, 100], {
    id: "setCollectionAttributes_setPrice0",
  });

  const passNFT = m.contract("CollectionNFT", [
    passConfig,
    nftRandomManager,
    "https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/rest/Token/GetTokenURI",
    "NFT Forge Pass",
    "NFP",
  ]);

  return { nftRandomManager, shopManager, passNFT, passManager };
});
