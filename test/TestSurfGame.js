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
  setupBoardAttributes,
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
      passNFT
    );

    const {
      collection: surfBoardCollectionConfig,
      collectionNFT: surfBoardCollectionNFT,
    } = await deployCollection(
      1,
      "Surboards of Sydney",
      setupBoardAttributes,
      nftRandomManager,
      shopManager,
      gameManager,
      passManager,
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

    const SurfForecastLib = await ethers.getContractFactory("SurfForecastLib");
    const surfForecastLib = await SurfForecastLib.deploy();
    // const SurfLib = await ethers.getContractFactory("SurfLib");
    // const surfLib = await SurfLib.deploy();

    const SurfGame = await ethers.getContractFactory("SurfGame", {
      libraries: { SurfForecastLib: surfForecastLib },
    });
    const surfGame = await SurfGame.deploy(
      nftRandomManager.target,
      surfForecastService.target
    );

    await surfGame.setSurfGameAddresses(
      surfCollectionNFT,
      surfBoardCollectionNFT
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

    await simulateWaveRequest("2581322212");

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
     * Wave is as expected
     *
     */
    it("Wave is as expected", async function () {
      const { surfGame, simulateWaveRequest } = await deployContracts();
      const WAVE_CONDITIONS_FROM_DAYS = 10;
      const NUMBER_OF_RUNS = 5;
      const INITIAL_DAYS_RAN = 1;

      await simulateWaveRequest("25525023013");
      const waveConditionsRaw = await surfGame.getCurrentWaveConditions();

      const lastWave = {
        waveMaxLength: waveConditionsRaw.waveMaxLength,
        wavePower: waveConditionsRaw.wavePower,
        waveSpeed: waveConditionsRaw.waveSpeed,
        waveCapacity: waveConditionsRaw.waveCapacity,
      };

      const lastWaveString = JSON.stringify(lastWave, bigIntParser);

      expect(lastWaveString).to.equal(
        '{"waveMaxLength":"55","wavePower":"50","waveSpeed":"30"}'
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
      await surfGame.performUpkeep("0x");

      await expect(addToQueueFunction()).to.not.be.reverted;
    });

    /**
     *
     * Queue is populated as expected
     *
     */
    it("Tests queue sizes", async function () {
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

      const oneSizeQueue = await surfGame.queueStatus(1);
      const fourSizeQueue = await surfGame.queueStatus(4);
      const fourtySizeQueue = await surfGame.queueStatus(40);

      expect(oneSizeQueue.length).to.equal(1);
      expect(fourSizeQueue.length).to.equal(4);
      expect(fourtySizeQueue.length).to.equal(numberOfSurfers);
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

      await simulateMockResponse(
        [
          74635414255432145646637716165700022762276637613562222667505622213773147566613n,
        ],
        20
      );

      surferPosition = await getSurferQueuePosition();
      expect(surferPosition).to.equal(firstRunSurferPosition);

      await surfGame.performUpkeep("0x");
      await surfGame.performUpkeep("0x");
      await surfGame.performUpkeep("0x");
      await surfGame.performUpkeep("0x");

      await surfGame.performUpkeep("0x");
      await surfGame.performUpkeep("0x");

      await addToQueueFunction();
      surferPosition = await getSurferQueuePosition();
      expect(surferPosition).to.equal(secondRunSurferPosition);
    });

    /**
     *
     * Tests Specific wave conditions
     *
     * 30541981550637216915197905245625419519679093509610777472708130704158474893086
     */
    it(" Tests Specific wave conditions", async function () {
      const {
        surfGame,
        simulateMockResponse,
        nftRandomManager,
        surfCollectionNFT,
        surfBoardCollectionNFT,
        shopManager,
        simulateWaveRequest,
      } = await deployContracts();

      await simulateWaveRequest("2591322412");

      const numberOfSurfers = 1;
      const surferId = 0;

      for (let i = 0; i < numberOfSurfers; i++) {
        await shopManager.mintNFT(surfCollectionNFT, "Surfer " + i);
        await simulateMockResponse(); //Random generator
        await shopManager.mintNFT(surfBoardCollectionNFT, "Board " + i);
        await simulateMockResponse(); //Random generator
        await surfGame.addSurferToQueue(
          surfCollectionNFT.target,
          i,
          surfBoardCollectionNFT.target,
          i
        );
      }

      logCollectionTraits(surfBoardCollectionNFT, 0);

      await simulateMockResponse(
        [
          18307275068061274254228106772891513395407423572721110282118756914193460810052n,
        ],
        20
      );

      await surfGame.performUpkeep("0x"); //Process wave 1 + 2 elements in the queue

      const roundZeroLogs = JSON.stringify(
        await surfGame.getRoundScore(0),
        bigIntParser
      );

      expect(roundZeroLogs).to.equal('[["0","0","75"]]');
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

      const expectedResult = `["0","0"]`;
      expect(JSON.stringify(result, bigIntParser).toLowerCase()).to.equal(
        expectedResult.toLowerCase()
      );
    });
    /**
     *
     * Test used to validate concepts
     *
     */
    // it("Gets waves seeds from random and process game", async function () {
    //   const {
    //     surfGame,
    //     simulateMockResponse,
    //     nftRandomManager,
    //     surfCollectionNFT,
    //     surfBoardCollectionNFT,
    //     shopManager,
    //   } = await deployContracts();

    //   const numberOfSurfers = 3;
    //   const surferId = 0;

    //   for (let i = 0; i < numberOfSurfers; i++) {
    //     await shopManager.mintNFT(surfCollectionNFT, "Surfer " + i);
    //     await simulateMockResponse(); //Random generator
    //     await shopManager.mintNFT(surfBoardCollectionNFT, "Board " + i);
    //     await simulateMockResponse(); //Random generator
    //     await surfGame.addSurferToQueue(
    //       surfCollectionNFT.target,
    //       i,
    //       surfBoardCollectionNFT.target,
    //       i
    //     );
    //   }

    //   await simulateMockResponse(
    //     [23895781004589149129578100458914450004564864664856305970002450n],
    //     20
    //   );

    //   while (await surfGame.canRun()) {
    //     await surfGame.performUpkeep("0x"); //Process wave 1 + 2 elements in the queue
    //   }
    //   //Should be called by the automation

    //   await surfGame.startNewRound();

    //   await surfGame.addSurferToQueue(
    //     surfCollectionNFT.target,
    //     surferId,
    //     surfBoardCollectionNFT.target,
    //     surferId
    //   );

    //   while (await surfGame.canRun()) {
    //     await surfGame.performUpkeep("0x"); //Process wave 1 + 2 elements in the queue
    //   }

    //   await surfGame.addSurferToQueue(
    //     surfCollectionNFT.target,
    //     surferId,
    //     surfBoardCollectionNFT.target,
    //     surferId
    //   );
    //   //Simulates the response of a wave request

    //   while (await surfGame.canRun()) {
    //     await surfGame.performUpkeep("0x"); //Process wave 1 + 2 elements in the queue
    //   }

    //   const logs = await surfGame.getSurferRunLog(
    //     surfCollectionNFT.target,
    //     surferId,
    //     0
    //   );
    //   logs.forEach((log) => {
    //     console.log(
    //       `Action: ${ethers.decodeBytes32String(
    //         log.actionName
    //       )} Current Speed: ${log.currentSpeed} Current Score: ${
    //         log.currentScore
    //       }`
    //     );
    //   });

    //   const nftJSONAttributes = (
    //     await surfCollectionNFT.getNFTDetails(surferId)
    //   )[1];

    //   let nft = { traits: [] };
    //   for (let i = 0; i < nftJSONAttributes.length; i++) {
    //     const attribute = nftJSONAttributes[i];
    //     if (attribute.isDefined) {
    //       let traitKey = attribute.key;
    //       let traitLabel = bytes32ToString(attribute.key);
    //       let traitValue;
    //       let traitImage;
    //       if (attribute.traitType === 1n) {
    //         traitValue = parseInt(attribute.value, 16);
    //       } else {
    //         traitValue = bytes32ToString(attribute.value);
    //         if (attribute.traitType === 2n) {
    //           traitImage = await collection.getTraitOptionsImage(
    //             attribute.key,
    //             attribute.value
    //           );
    //         }
    //       }
    //       nft.traits.push({ traitKey, traitLabel, traitValue, traitImage });
    //     }
    //   }
    //   console.log(nft);

    //   const roundZeroLogs = await surfGame.getRoundScore(0);
    //   console.log(roundZeroLogs);

    //   const roundOneLogs = await surfGame.getRoundScore(1);
    //   console.log(roundOneLogs);
    //   // console.log(`Log Length: ${logs.length}`);
    // });
  });
});

const logCollectionTraits = async (collection, id) => {
  const nftJSONAttributes = (await collection.getNFTDetails(id))[1];

  let nft = { traits: [] };
  for (let i = 0; i < nftJSONAttributes.length; i++) {
    const attribute = nftJSONAttributes[i];
    if (attribute.isDefined) {
      let traitKey = attribute.key;
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
      nft.traits.push({ traitKey, traitLabel, traitValue, traitImage });
    }
  }
  //console.log(nft);
};

const bigIntParser = (key, value) => {
  return typeof value === "bigint" ? value.toString() : value;
};
