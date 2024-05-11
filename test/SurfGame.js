const {} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { string } = require("hardhat/internal/core/params/argumentTypes");

const {
  deployContractsInfrastructure,
  deployCollection,
  stringToBytes32,
  bytes32ToString,
  grantRandomManagerRoles,
  addManagedCollectionToNFTManager,
} = require("./Configs/CommonPreparation.js");

const {
  setupCharacterAttributes,
} = require("./Configs/BaseCollectionConfiguration.js");

//npx hardhat test ./test/SurfGame.js
describe("Surf Game", function () {
  async function deployContracts() {
    const [owner, otherAccount] = await ethers.getSigners();

    const {
      mockCoordinator,
      nftRandomManager,
      shopManager,
      gameManager,
      passManager,
      passConfig,
      passNFT,
    } = await deployContractsInfrastructure();

    const {
      collection: surfCollectionConfig,
      collectionNFT: surfCollectionNFT,
    } = await deployCollection(
      0,
      "Surfers of Sydney",
      null,
      nftRandomManager,
      shopManager,
      gameManager,
      passManager,
      passConfig,
      passNFT
    );

    const {
      collection: surfBoardCollectionConfig,
      collectionNFT: surfBoardCollectionNFT,
    } = await deployCollection(
      1,
      "Surboards of Sydney",
      null,
      nftRandomManager,
      shopManager,
      gameManager,
      passManager,
      passConfig,
      passNFT
    );

    const SurfGame = await ethers.getContractFactory("SurfGame");
    const surfGame = await SurfGame.deploy(nftRandomManager.target);

    await grantRandomManagerRoles(nftRandomManager, surfGame);
    await addManagedCollectionToNFTManager(surfGame, surfCollectionNFT);
    await addManagedCollectionToNFTManager(surfGame, surfBoardCollectionNFT);

    return {
      surfGame,
      mockCoordinator,
      nftRandomManager,
      surfCollectionNFT,
      surfBoardCollectionNFT,
      shopManager,
    };
  }

  describe("Test Game Loop", function () {
    // it("Test a direct run ", async function () {
    //   const { surfGame } = await deployContracts();

    //   await surfGame.doRun(
    //     23895781004589149129578100458914450004564864664856305970002450n
    //   );

    //   let logs = await surfGame.getRun(0);
    //   console.log("Run 1");
    //   logs.forEach((log) => {
    //     console.log(
    //       `Action: ${ethers.decodeBytes32String(
    //         log.actionName
    //       )} Current Speed: ${log.currentSpeed} Current Score: ${
    //         log.currentScore
    //       }`
    //     );
    //   });
    //   console.log(`Log Length: ${logs.length}`);

    //   console.log("Run 2");
    //   await surfGame.doRun(
    //     22223344010101010101010101010101010101010101010101010101010101010101010101055n
    //   );

    //   logs = await surfGame.getRun(1);
    //   logs.forEach((log) => {
    //     console.log(
    //       `Action: ${ethers.decodeBytes32String(
    //         log.actionName
    //       )} Current Speed: ${log.currentSpeed} Current Score: ${
    //         log.currentScore
    //       }`
    //     );
    //   });
    //   console.log(`Log Length: ${logs.length}`);
    // });
    it("Fails to add surfer that is not owned", async function () {
      const {
        surfGame,
        mockCoordinator,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      const [owner, otherAccount] = await ethers.getSigners();

      await shopManager
        .connect(otherAccount)
        .mintNFT(surfCollectionNFT, "Surfer ");
      await shopManager.mintNFT(surfBoardCollectionNFT, "Board ");
      // await surfGame.addSurferToQueue(
      //   surfCollectionNFT.target,
      //   0,
      //   surfBoardCollectionNFT.target,
      //   0
      // );
    });
    it("Gets waves seeds from random and process game", async function () {
      const {
        surfGame,
        mockCoordinator,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      const numberOfSurfers = 5;

      for (let i = 0; i < numberOfSurfers; i++) {
        await shopManager.mintNFT(surfCollectionNFT, "Surfer " + i);
        await shopManager.mintNFT(surfBoardCollectionNFT, "Board " + i);
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          i,
          surfBoardCollectionNFT.target,
          i
        );
      }

      //Simulates the response of a wave request
      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [
          23895781004589149129578100458914450004564864664856305970002450n,
          22223344010101010101010101010101010101010101010101010101010101010101010101055n,
        ]
      );

      //Should be called by the automation
      await surfGame.runGame(); //Process wave 1 + 2 elements in the queue
      await surfGame.runGame(); //Process wave 2 + 2 elements in the queue

      //Simulates the response of a wave request
      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [
          23895781004589149129578100458914450004564864664856305970002450n,
          22223344010101010101010101010101010101010101010101010101010101010101010101055n,
        ]
      );

      await surfGame.runGame(); //Process wave 3 + 2 elements in the queue

      const logs = await surfGame.getSurferLogs(surfCollectionNFT.target, 4);
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
