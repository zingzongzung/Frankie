const {} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { string } = require("hardhat/internal/core/params/argumentTypes");

//npx hardhat test ./test/SurfGame.js
describe("NFT collectionNFT", function () {
  async function deployContracts() {
    const [owner, otherAccount] = await ethers.getSigners();

    const MockCoordinator = await ethers.getContractFactory("MockCoordinator");
    const mockCoordinator = await MockCoordinator.deploy();

    const NFTRandomManager = await ethers.getContractFactory(
      "NFTRandomManager"
    );
    const nftRandomManager = await NFTRandomManager.deploy(
      /* VRF Subscription Id */ 5,
      mockCoordinator.target,
      "0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61" //Key Hash
    );

    const SurfGame = await ethers.getContractFactory("SurfGame");
    const surfGame = await SurfGame.deploy(nftRandomManager.target);

    return { surfGame };
  }

  describe("Test Game Loop", function () {
    it("Loops through the game and returns a run log", async function () {
      const { surfGame } = await deployContracts();

      await surfGame.run(
        23895781004589149129578100458914450004564864664856305970002450n
      );

      let logs = await surfGame.getRun(0);
      console.log("Run 1");
      logs.forEach((log) => {
        console.log(
          `Action: ${ethers.decodeBytes32String(
            log.actionName
          )} Current Speed: ${log.currentSpeed} Current Score: ${
            log.currentScore
          }`
        );
      });
      console.log(`Log Length: ${logs.length}`);

      console.log("Run 2");
      await surfGame.run(
        22223344010101010101010101010101010101010101010101010101010101010101010101055n
      );

      logs = await surfGame.getRun(1);
      logs.forEach((log) => {
        console.log(
          `Action: ${ethers.decodeBytes32String(
            log.actionName
          )} Current Speed: ${log.currentSpeed} Current Score: ${
            log.currentScore
          }`
        );
      });
      console.log(`Log Length: ${logs.length}`);
    });
  });
});
