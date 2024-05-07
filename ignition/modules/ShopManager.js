const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { roles, priceFeed, admins } = require("./Configurations.json");

module.exports = buildModule("ShopManager", (m) => {
  const shopManager = m.contract("ShopManager", [priceFeed.AvaxUSD]);

  admins.forEach((adminAddress, i) => {
    //Grant Admin Roles
    m.call(shopManager, "grantRole", [roles.defaultAdmin, adminAddress], {
      id: `grantRole_Admin${i}`,
    });
  });

  return { passManager };
});
