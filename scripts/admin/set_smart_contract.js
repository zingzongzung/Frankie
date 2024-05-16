const fs = require("fs");
const path = require("path");
require("@chainlink/env-enc").config();

const resources = {
  CollectionNFT: {
    artifact:
      "./../../artifacts/contracts/collection/collection_nft/CollectionNFT.sol/CollectionNFT.json",
    type: 1,
  },
  CollectionConfig: {
    artifact:
      "./../../artifacts/contracts/collection/collection_config/CollectionConfig.sol/CollectionConfig.json",
    type: 2,
  },

  NFTRandomManager: {
    artifact:
      "./../../artifacts/contracts/managers/random/NFTRandomManager.sol/NFTRandomManager.json",
    type: 3,
  },
  ShopManager: {
    artifact:
      "./../../artifacts/contracts/managers/nfts/ShopManager.sol/ShopManager.json",
    type: 4,
  },
  PassManager: {
    artifact:
      "./../../artifacts/contracts/managers/nfts/PassManager.sol/PassManager.json",
    type: 5,
  },
  PassNFT: {
    artifact:
      "./../../artifacts/contracts/collection/collection_nft/CollectionNFT.sol/CollectionNFT.json",
    type: 7,
  },
  SurfGame: {
    artifact:
      "./../../artifacts/contracts/games/surf/SurfGame.sol/SurfGame.json",
    type: 8,
  },
};

const setSmartContract = (contractName, secretsURL) => {
  const source = JSON.parse(
    fs
      .readFileSync(path.resolve(__dirname, resources[contractName].artifact))
      .toString()
  );

  const abiAsExpected = { abi: source.abi };

  const requestData = {
    ABI: JSON.stringify(abiAsExpected),
    ByteCode: source.bytecode || "",
    ContractAddress: getContractAddress(contractName) || "",
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
        throw new Error("Network response was not ok " + response.statusText);
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

const main = () => {
  const param = process.argv.length > 2 ? process.argv[2] : "ALL";

  if (param === "ALL") {
    Object.keys(resources).forEach((key) => {
      setSmartContract(key);
    });
  } else if (param === "help") {
    console.log(resources);
  } else {
    setSmartContract(param);
  }
};

main();
