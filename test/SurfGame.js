const {} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { string, json } = require("hardhat/internal/core/params/argumentTypes");

const {
  deployContractsInfrastructure,
  deployCollection,
  stringToBytes32,
  bytes32ToString,
  grantRandomManagerRoles,
  addManagedCollectionToNFTManager,
  grantSurfConsumerRoles,
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

    const MockFunctionsRouter = await ethers.getContractFactory(
      "MockFunctionsRouter"
    );
    const mockFunctionsRouter = await MockFunctionsRouter.deploy();

    const SurfForecastService = await ethers.getContractFactory(
      "SurfForecastService"
    );
    const surfForecastService = await SurfForecastService.deploy(
      /* should be cooredinater address */ mockFunctionsRouter.target
    );

    await surfForecastService.setForecastServiceConfig(
      "console.log('teste')",
      ethers.toUtf8Bytes("dummyvalue"),
      300000,
      ethers.encodeBytes32String("dummyvalue"),
      34
    );

    const SurfGame = await ethers.getContractFactory("SurfGame");
    const surfGame = await SurfGame.deploy(
      nftRandomManager.target,
      surfForecastService.target
    );

    await grantSurfConsumerRoles(surfForecastService, surfGame);
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
      mockFunctionsRouter,
      surfForecastService,
    };
  }

  describe("Surf Forecast integration", function () {
    /**
     *
     * Test Parser
     *
     */
    it("Test Surf waves count", async function () {
      const { surfGame, mockFunctionsRouter, surfForecastService } =
        await deployContracts();

      await surfGame.sendRequest();
      await mockFunctionsRouter.mockResponse(
        surfForecastService.target,
        ethers.toUtf8Bytes("25525023012")
      );

      let waveConditions = await surfGame.getWaveConditionsFromLastDays(10);
      console.log(waveConditions.length);

      await surfGame.sendRequest();
      await mockFunctionsRouter.mockResponse(
        surfForecastService.target,
        ethers.toUtf8Bytes("25625023012")
      );
      await surfGame.sendRequest();
      await mockFunctionsRouter.mockResponse(
        surfForecastService.target,
        ethers.toUtf8Bytes("25725023012")
      );
      await surfGame.sendRequest();
      await mockFunctionsRouter.mockResponse(
        surfForecastService.target,
        ethers.toUtf8Bytes("25825023012")
      );
      await surfGame.sendRequest();
      await mockFunctionsRouter.mockResponse(
        surfForecastService.target,
        ethers.toUtf8Bytes("25925023012")
      );
      //SurfTypes.SurfWave(SurfTypes.SUPER_TUBOS, 55 /* waveMaxLength */, 50 /* power */, 30 /* speed */, SurfTypes.WaveSide.Left, 2 /* wave capacity */);

      waveConditions = await surfGame.getWaveConditionsFromLastDays(10);
      console.log(waveConditions.length);

      const exampleResponse = ethers.toUtf8Bytes("310031001");

      const parsedResult = await surfGame.testParser(exampleResponse);

      console.log(parsedResult);
    });
  });

  describe("Test Game Loop", function () {
    /**
     *
     * Verify ownership on game play
     *
     */
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

      const addToQueueFunction = async () => {
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          0,
          surfBoardCollectionNFT.target,
          0
        );
      };

      await expect(addToQueueFunction()).to.be.revertedWith(
        "Not owner of the NFT"
      );
    });
    /**
     *
     * Tests Surfer only added once to the queue at any given time
     *
     */
    it("Add surfer only once", async function () {
      const {
        surfGame,
        mockCoordinator,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      await shopManager.mintNFT(surfCollectionNFT, "Surfer ");
      await shopManager.mintNFT(surfBoardCollectionNFT, "Board ");

      const addToQueueFunction = async () => {
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          0,
          surfBoardCollectionNFT.target,
          0
        );
      };

      await addToQueueFunction();

      await expect(addToQueueFunction()).to.be.revertedWith(
        "Surfer is already queued"
      );
    });
    /**
     *
     * Tests Surfer can be added again after getting out of the queue
     *
     */
    it("Add surfer to queue again after the game has run", async function () {
      const {
        surfGame,
        mockCoordinator,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      await shopManager.mintNFT(surfCollectionNFT, "Surfer ");
      await shopManager.mintNFT(surfBoardCollectionNFT, "Board ");

      const addToQueueFunction = async () => {
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          0,
          surfBoardCollectionNFT.target,
          0
        );
      };
      await addToQueueFunction();

      //Simulates the game running (Response from VRF + automation runing the game loop)
      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [
          23895781004589149129578100458914450004564864664856305970002450n,
          22223344010101010101010101010101010101010101010101010101010101010101010101055n,
        ]
      );
      await surfGame.runGame();

      await expect(addToQueueFunction()).to.not.be.reverted;
    });
    /**
     *
     * The queue position of a surfer in a  first run and in a second run is different
     *
     */
    it("The queue position of a surfer in a  first run and in a second run is different", async function () {
      const {
        surfGame,
        mockCoordinator,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      const numberOfSurfers = 5;
      const surferTokenId = 1;
      const queueOffset = 1;
      const firstRunSurferPosition = surferTokenId + queueOffset;
      const secondRunSurferPosition = numberOfSurfers + queueOffset;

      const getSurferQueuePosition = async () => {
        return await surfGame.getSurferQueuePosition(
          surfCollectionNFT.target,
          surferTokenId
        );
      };

      const addToQueueFunction = async () => {
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          surferTokenId,
          surfBoardCollectionNFT.target,
          surferTokenId
        );
      };

      let surferPosition = await getSurferQueuePosition();
      expect(surferPosition).to.equal(0);

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

      surferPosition = await getSurferQueuePosition();
      expect(surferPosition).to.equal(firstRunSurferPosition);

      //Simulates the game running (Response from VRF + automation runing the game loop)
      await mockCoordinator.mockVRFCoordinatorResponse(
        nftRandomManager.target,
        [
          23895781004589149129578100458914450004564864664856305970002450n,
          22223344010101010101010101010101010101010101010101010101010101010101010101055n,
        ]
      );
      await surfGame.runGame();

      await addToQueueFunction();
      surferPosition = await getSurferQueuePosition();
      expect(surferPosition).to.equal(secondRunSurferPosition);
    });
    /**
     *
     * Can get the surfer object at a specific position
     *
     */
    it("Can get the surfer object at a specific position", async function () {
      const {
        surfGame,
        mockCoordinator,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      await shopManager.mintNFT(surfCollectionNFT, "Surfer ");
      await shopManager.mintNFT(surfBoardCollectionNFT, "Board ");

      const addToQueueFunction = async () => {
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          0,
          surfBoardCollectionNFT.target,
          0
        );
      };
      await addToQueueFunction();

      const getSurferQueuePosition = async () => {
        return await surfGame.getSurferQueuePosition(
          surfCollectionNFT.target,
          0
        );
      };

      const result = await surfGame.getSurferAtPosition(
        await getSurferQueuePosition()
      );

      const expectedResult = `["${surfCollectionNFT.target}","0","${surfBoardCollectionNFT.target}","0"]`;
      expect(JSON.stringify(result, bigIntParser).toLowerCase()).to.equal(
        expectedResult.toLowerCase()
      );
    });
    /**
     *
     * Test used to validate concepts
     *
     */
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

      // console.log(await surfGame.queueStatus());

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

      // const logs = await surfGame.getSurferLogs(surfCollectionNFT.target, 4);
      // logs.forEach((log) => {
      //   console.log(
      //     `Action: ${ethers.decodeBytes32String(
      //       log.actionName
      //     )} Current Speed: ${log.currentSpeed} Current Score: ${
      //       log.currentScore
      //     }`
      //   );
      // });
      // console.log(`Log Length: ${logs.length}`);
    });
  });
});

const bigIntParser = (key, value) => {
  return typeof value === "bigint" ? value.toString() : value;
};
