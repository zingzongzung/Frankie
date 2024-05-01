const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("NFTRandomManager", (m) => {
  const owner = m.getAccount(0);

  const nftRandomManager = m.contract("NFTRandomManager", [1863]);

  //   m.call(genesisCollection, "grantRole", [,0x2Ee45000a92ABeeF70ABDEFA2432ACB66dbc3F30]);

  const basicNFT = m.contract("BasicNFT", [
    owner,
    "0xacd3A96C55661501f54bB1AFbA6e8DDb2e595C56",
    nftRandomManager,
  ]);

  m.call(nftRandomManager, "grantRole", [
    "0xba97d1e7c7cac970a86143e4a79d94ccf81090bb6c8dfb9571552cb2226d115c",
    basicNFT,
  ]);

  return { nftRandomManager };
});

/**
 * 
 * 
 * NFTMaker#GenesisCollection - 0xacd3A96C55661501f54bB1AFbA6e8DDb2e595C56
NFTMaker#NFTRandomManager - 0x04CECE2960D3fA3133f23b561078464d9e197dF0
NFTMaker#BasicNFT - 0x2Ee45000a92ABeeF70ABDEFA2432ACB66dbc3F30


 */
