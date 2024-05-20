const fs = require("fs");
const path = require("path");
require("@chainlink/env-enc").config();

const resources = {
  CollectionNFT: {
    artifact:
      "./../../artifacts/contracts/collection/collection_nft/CollectionNFT.sol/CollectionNFT.json",
    type: 1,
    needsAddress: false,
  },
  CollectionConfig: {
    artifact:
      "./../../artifacts/contracts/collection/collection_config/CollectionConfig.sol/CollectionConfig.json",
    type: 2,
    needsAddress: false,
  },

  NFTRandomManager: {
    artifact:
      "./../../artifacts/contracts/managers/random/NFTRandomManager.sol/NFTRandomManager.json",
    type: 3,
    needsAddress: true,
  },
  ShopManager: {
    artifact:
      "./../../artifacts/contracts/managers/nfts/ShopManager.sol/ShopManager.json",
    type: 4,
    needsAddress: true,
  },
  PassManager: {
    artifact:
      "./../../artifacts/contracts/managers/nfts/PassManager.sol/PassManager.json",
    type: 5,
    needsAddress: true,
  },
  PassNFT: {
    artifact:
      "./../../artifacts/contracts/collection/collection_nft/CollectionNFT.sol/CollectionNFT.json",
    type: 7,
    needsAddress: true,
  },
  SurfGame: {
    artifact:
      "./../../artifacts/contracts/games/surf/SurfGame.sol/SurfGame.json",
    type: 8,
    isGame: true,
    needsAddress: true,
  },
  PassConfig: {
    artifact:
      "./../../artifacts/contracts/collection/collection_config/PassConfig.sol/PassConfig.json",
    type: 9,
    needsAddress: true,
  },
};

const setSmartContract = (contractName) => {
  const source = JSON.parse(
    fs
      .readFileSync(path.resolve(__dirname, resources[contractName].artifact))
      .toString()
  );

  const abiAsExpected = { abi: source.abi };
  const jsonABI = JSON.stringify(abiAsExpected) || "";

  const contractAddress = getContractAddress(contractName) || "";
  const sourceBytecode = source.bytecode || "";

  //Run Validations
  if (resources[contractName].needsAddress && contractAddress === "") {
    console.error(`Error: ${contractName} Details: Missing Address`);
    return;
  }

  if (!resources[contractName].needsAddress && sourceBytecode === "") {
    console.error(`Error: ${contractName} Details: Missing Bytecode`);
    return;
  }

  if (jsonABI === "") {
    console.error(`Error: ${contractName} Details: Missing ABI`);
    return;
  }

  const requestData = {
    ABI: jsonABI,
    ByteCode: sourceBytecode,
    ContractAddress: contractAddress,
    SmartContractType: resources[contractName].type || 0,
  };

  const requestDataJSON = JSON.stringify(requestData);

  // Username and password
  const username = process.env.OS_ADMIN;
  const password = process.env.OS_ADMIN_PASS;

  // Base64 encode the credentials
  const credentials = btoa(username + ":" + password);

  // Create the Authorization header
  const authHeaderValue = `Basic ${credentials}`;

  fetch(
    `https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/rest/Admin/UploadSmartContractCode`,
    {
      headers: {
        Authorization: authHeaderValue,
        "Content-Type": "application/json",
      },
      method: "POST",
      body: requestDataJSON,
    }
  )
    .then((response) => {
      if (!response.ok) {
        console.error("Network response was not ok " + response.statusText);
      } else {
        console.log(`Sent: ${contractName}`);
      }
    })
    .catch((error) =>
      console.error("There was a problem with your fetch operation:", error)
    );
};

const getContractAddress = (contractName) => {
  const source = JSON.parse(
    fs
      .readFileSync(
        path.resolve(
          __dirname,
          "./../../ignition/deployments/chain-43113/deployed_addresses.json"
        )
      )
      .toString()
  );
  const addresses = {};
  Object.keys(source).forEach((key) => {
    const newKey = key.split("#")[1];
    addresses[newKey] = source[key];
  });

  return addresses[contractName];
};

module.exports = {
  setSmartContract,
};

const commands = {
  help: { name: "help", description: "See command options" },
  games: { name: "games", description: "Send all games contract information" },
  baseContracts: {
    name: "base",
    description: "Send all base contracts information",
  },
  all: {
    name: "all",
    description: "Send all base contracts + games contracts information",
  },
};

const main = () => {
  const baseParam =
    process.argv.length > 2 ? process.argv[2] : commands.baseContracts.name;
  const param = baseParam.replace("--", "");

  if (param === commands.games.name) {
    Object.keys(resources).forEach((key) => {
      if (resources[key].isGame) {
        setSmartContract(key);
      }
    });
  } else if (param === commands.baseContracts.name) {
    Object.keys(resources).forEach((key) => {
      if (!resources[key].isGame) {
        setSmartContract(key);
      }
    });
  } else if (param === commands.all.name) {
    Object.keys(resources).forEach((key) => {
      setSmartContract(key);
    });
  } else if (param === commands.help.name) {
    console.log("\n\nGeneral:");
    Object.keys(commands).forEach((key) => {
      console.log(
        `Use --${commands[key].name} to ${commands[key].description}`
      );
    });
    console.log("\n\nBy Contract:");
    Object.keys(resources).forEach((key) => {
      console.log(`Use: --${key} to send only this contract`);
    });
  } else {
    setSmartContract(param);
  }
};

main();
