const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { roles, priceFeed, admins } = require("./Configurations.json");

//npx hardhat ignition deploy ignition/modules/01_DeployInfrastructure.js --network fuji --reset
module.exports = buildModule("PassManager", (m) => {
  const passManager = m.contract("PassManager", [priceFeed.AvaxUSD]);

  admins.forEach((adminAddress, i) => {
    //Grant Admin Roles
    m.call(passManager, "grantRole", [roles.defaultAdmin, adminAddress], {
      id: `grantRole_Admin${i}`,
    });
  });

  return { passManager };
});
