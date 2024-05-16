const { task } = require("hardhat/config");

task("compile-specific", "Compiles Function router").setAction(
  async (taskArgs, hre) => {
    const filePath =
      "/Users/zingzongzung/Documents/Projects/Chainlink Block Magic Hackaton/collection/node_modules/@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsRouter.sol";

    hre.config.paths.sources = filePath;

    await hre.run("compile");
  }
);
