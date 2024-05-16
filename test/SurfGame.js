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
      nftRandomManager,
      shopManager,
      gameManager,
      passManager,
      passConfig,
      passNFT,
      simulateMockResponse,
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

    //Simulate 1st request to set the wave for the first day
    const simulateWaveRequest = async (waveConditionsBytes) => {
      await surfGame.sendRequest();
      await mockFunctionsRouter.mockResponse(
        surfForecastService.target,
        ethers.toUtf8Bytes(waveConditionsBytes)
      );
    };

    await simulateWaveRequest("25525023012");

    return {
      surfGame,
      nftRandomManager,
      surfCollectionNFT,
      surfBoardCollectionNFT,
      shopManager,
      mockFunctionsRouter,
      surfForecastService,
      simulateWaveRequest,
      simulateMockResponse,
    };
  }

  describe("Surf Forecast integration", function () {
    /**
     *
     * Test Waves Count
     *
     */
    it("Test Surf waves count", async function () {
      const { surfGame, simulateWaveRequest } = await deployContracts();
      const WAVE_CONDITIONS_FROM_DAYS = 10;
      const NUMBER_OF_RUNS = 5;
      const INITIAL_DAYS_RAN = 1;

      let waveConditions = await surfGame.getWaveConditionsFromLastDays(
        WAVE_CONDITIONS_FROM_DAYS
      );
      expect(waveConditions.length).to.equal(INITIAL_DAYS_RAN);

      for (let i = 0; i < NUMBER_OF_RUNS; i++) {
        await simulateWaveRequest("25525023012");
      }
      //SurfTypes.SurfWave(SurfTypes.SUPER_TUBOS, 55 /* waveMaxLength */, 50 /* power */, 30 /* speed */, SurfTypes.WaveSide.Left, 2 /* wave capacity */);

      waveConditions = await surfGame.getWaveConditionsFromLastDays(
        WAVE_CONDITIONS_FROM_DAYS
      );
      expect(waveConditions.length).to.equal(
        WAVE_CONDITIONS_FROM_DAYS > NUMBER_OF_RUNS
          ? NUMBER_OF_RUNS + INITIAL_DAYS_RAN
          : WAVE_CONDITIONS_FROM_DAYS
      );
    });
    /**
     *
     * Wave is as expected
     *
     */
    it("Wave is as expected", async function () {
      const { surfGame, simulateWaveRequest } = await deployContracts();
      const WAVE_CONDITIONS_FROM_DAYS = 10;
      const NUMBER_OF_RUNS = 5;
      const INITIAL_DAYS_RAN = 1;

      await simulateWaveRequest("25525023013");
      const waveConditions = await surfGame.getWaveConditionsFromLastDays(
        WAVE_CONDITIONS_FROM_DAYS
      );

      const lastWave = {
        waveMaxLength: waveConditions[0].waveMaxLength,
        wavePower: waveConditions[0].wavePower,
        waveSpeed: waveConditions[0].waveSpeed,
        waveCapacity: waveConditions[0].waveCapacity,
      };

      const lastWaveString = JSON.stringify(lastWave, bigIntParser);

      expect(lastWaveString).to.equal(
        '{"waveMaxLength":"55","wavePower":"50","waveSpeed":"30","waveCapacity":"3"}'
      );
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
        simulateMockResponse,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      const [owner, otherAccount] = await ethers.getSigners();

      await shopManager
        .connect(otherAccount)
        .mintNFT(surfCollectionNFT, "Surfer ");
      await simulateMockResponse();
      await shopManager.mintNFT(surfBoardCollectionNFT, "Board ");
      await simulateMockResponse();

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
    it("Add surfer or surfboard only once to queue", async function () {
      const {
        surfGame,
        simulateMockResponse,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      //mint 2 surfers
      await shopManager.mintNFT(surfCollectionNFT, "Surfer ");
      await simulateMockResponse();
      await shopManager.mintNFT(surfCollectionNFT, "Surfer ");
      await simulateMockResponse();

      //mint 1 surfboard
      await shopManager.mintNFT(surfBoardCollectionNFT, "Board ");
      await simulateMockResponse();

      const addToQueueFunction = async (surferId, surfboardId) => {
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          surferId,
          surfBoardCollectionNFT.target,
          surfboardId
        );
      };

      //add surfer 0 and surfboard 0 to queue
      await addToQueueFunction(0, 0);
      await expect(addToQueueFunction(0, 0)).to.be.revertedWith(
        "Surfer is already queued"
      );
      addToQueueFunction(1, 0);
      await expect(addToQueueFunction(1, 0)).to.be.revertedWith(
        "Surfboard is already queued"
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
        simulateMockResponse,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      await shopManager.mintNFT(surfCollectionNFT, "Surfer ");
      await simulateMockResponse();
      await shopManager.mintNFT(surfBoardCollectionNFT, "Board ");
      await simulateMockResponse();

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
      await simulateMockResponse([
        23895781004589149129578100458914450004564864664856305970002450n,
        22223344010101010101010101010101010101010101010101010101010101010101010101055n,
      ]);
      await surfGame.runGame();
      const dynamicTraits = await surfCollectionNFT.getDynamicTraits();
      console.log(dynamicTraits);

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
        simulateMockResponse,
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
        await simulateMockResponse();
        await shopManager.mintNFT(surfBoardCollectionNFT, "Board " + i);
        await simulateMockResponse();
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
      await simulateMockResponse([
        23895781004589149129578100458914450004564864664856305970002450n,
        22223344010101010101010101010101010101010101010101010101010101010101010101055n,
      ]);
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
        simulateMockResponse,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      await shopManager.mintNFT(surfCollectionNFT, "Surfer ");
      await simulateMockResponse();
      await shopManager.mintNFT(surfBoardCollectionNFT, "Board ");
      await simulateMockResponse();

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
        simulateMockResponse,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
      } = await deployContracts();

      const numberOfSurfers = 2;
      const surferId = 0;

      for (let i = 0; i < numberOfSurfers; i++) {
        await shopManager.mintNFT(surfCollectionNFT, "Surfer " + i);
        await simulateMockResponse();
        await shopManager.mintNFT(surfBoardCollectionNFT, "Board " + i);
        await simulateMockResponse();
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          i,
          surfBoardCollectionNFT.target,
          i
        );
      }

      // console.log(await surfGame.queueStatus());

      //Simulates the response of a wave request
      await simulateMockResponse([
        23895781004589149129578100458914450004564864664856305970002450n,
        22223344010101010101010101010101010101010101010101010101010101010101010101055n,
      ]);
      //Should be called by the automation
      await surfGame.runGame(); //Process wave 1 + 2 elements in the queue
      await surfGame.addSurferToQueue(
        surfCollectionNFT.target,
        surferId,
        surfBoardCollectionNFT.target,
        surferId
      );
      await surfGame.runGame(); //Process wave 2 + 2 elements in the queue
      await surfGame.addSurferToQueue(
        surfCollectionNFT.target,
        surferId,
        surfBoardCollectionNFT.target,
        surferId
      );
      //Simulates the response of a wave request
      await simulateMockResponse([
        23895781004589149129578100458914450004564864664856305970002450n,
        23895781004589149129578100458914450004564864664856305970002450n,
      ]);

      await surfGame.runGame(); //Process wave 3 + 2 elements in the queue

      const logs = await surfGame.getSurferRunLog(
        surfCollectionNFT.target,
        surferId,
        0
      );
      logs.forEach((log) => {
        console.log(
          `Action: ${ethers.decodeBytes32String(
            log.actionName
          )} Current Speed: ${log.currentSpeed} Current Score: ${
            log.currentScore
          }`
        );
      });

      const nftJSONAttributes = (
        await surfCollectionNFT.getNFTDetails(surferId)
      )[1];

      let nft = { traits: [] };
      for (let i = 0; i < nftJSONAttributes.length; i++) {
        const attribute = nftJSONAttributes[i];
        if (attribute.isDefined) {
          let traitLabel = bytes32ToString(attribute.key);
          let traitValue;
          let traitImage;
          if (attribute.traitType === 1n) {
            traitValue = parseInt(attribute.value, 16);
          } else {
            traitValue = bytes32ToString(attribute.value);
            if (attribute.traitType === 2n) {
              traitImage = await collection.getTraitOptionsImage(
                attribute.key,
                attribute.value
              );
            }
          }
          nft.traits.push({ traitLabel, traitValue, traitImage });
        }
      }
      console.log(nft);

      // console.log(`Log Length: ${logs.length}`);
    });
  });
});

const bigIntParser = (key, value) => {
  return typeof value === "bigint" ? value.toString() : value;
};
