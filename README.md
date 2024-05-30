# Frankie - Chainlink Hackathon

This repository contains the smart contracts for two distinct functionalities:

1. **Create Your Unique NFT Collections**: Create highly customizable NFT collections, persisting all trait definitions and NFT data on-chain.
2. **Game Use Case**: Utilize the generated NFTs in a game.

This project was created for the 2024 Chainlink Hackathon and targets the Avalanche network. It should work on any EVM-compatible chain supported by the following Chainlink products:

- VRF
- Functions
- Price Feed
- Automation

## Overview

### Collection Management

The collection management functionality allows users to create unique NFT collections with customizable traits. Each collection's trait definitions and NFT data are stored on-chain, ensuring transparency and immutability. The architecture is designed to be flexible, supporting various customization options for the NFTs.

#### Flow

The way it works is as follows:

1. **CollectionConfig Smart Contract**: This contract must be deployed after all the traits are known and configured. In our case, we have created a frontend for this purpose. The `CollectionConfig` contract will contain all the trait information, including:

   - **Name**: The name of the trait.
   - **Visual Representation**: A hash of the content representing the trait.
   - **Chance**: The probability of generating an NFT with the specific trait.

2. **Collection Smart Contract**: Once the `CollectionConfig` is set, a collection smart contract must be deployed, pointing to this `CollectionConfig`. These smart contracts can be deployed by any wallet, as long as they have a pass ID, a collection name, and a signature from the wallet that owns the pass. The collection smart contract is part of the system providing the solution, but the wallet owning the pass determines if it can be deployed.

3. **Role Assignment**: After deploying the contracts and syncing the traits, the necessary roles must be assigned:
   - Grant the `NFT Manager` role to both the `CollectionNFT` smart contract and the `NFTRandomManager` contract.
   - Grant the `Shop Manager` role to both the `CollectionNFT` smart contract and the `ShopManager` contract.

#### Future Improvements

For future iterations, we aim to enhance the synchronization of traits to make it bulletproof. Additionally, a new signature should be requested from the pass owner for every interaction with the smart contract. This separation allows us, as a product, to assume the gas costs.

### Surf Game

The surf game integrates the generated NFTs into an engaging on-chain game. Players need both a surfer and a surfboard NFT to participate. The game leverages Chainlink services for various functionalities, including wave condition updates and random event generation.

#### Flow

The way it works is as follows:

1. **Collections Requirement**: The surf game requires two collections generated with our collection management tool:

   - **Surfer Collection**: Represents the surfer NFT.
   - **Surfboard Collection**: Represents the surfboard NFT, which must have a Speed trait of type Range/Number.

2. **Wave Conditions**: The game uses a marine forecast system to set the current wave conditions. We have developed a formula to convert direction, wave height, and wave period into gamified properties, namely wave length, wave speed, and base multiplier.

3. **Queue and Wave Seeds**: Surfers are added to a queue by the NFT owners. If there are no wave seeds in the game pool (generated by Chainlink VRF), a new request for 10 seeds is made.

4. **Game Execution**: The game is executed periodically by the Chainlink automation engine, under the following conditions:

   - The defined threshold time has passed.
   - There are surfers waiting for waves.
   - The wave condition has been correctly set.

   If the game loop detects no wave seeds in the pool (typically occurring if more than 10 surfers are added to the queue before the game loop runs), it will request more wave seeds and will run on the next cycle.

5. **Game Loop**: During execution, the game loop:
   - Uses a wave seed.
   - Combines it with the board speed and the wave conditions.
   - Generates a random set of actions resulting in a surf wave log with a given score.

#### Future Improvements

For future iterations, the set of actions should be determined by the surfer's level, experience, and skills.

## Supported Chains and Chainlink Products

## Unit Tests

We have built unit tests to test both the collection and the surf game. To run them, execute:

```bash
npx hardhat test test/TestCommon.js
npx hardhat test test/TestCollection.js
npx hardhat test test/TestSurfGame.js
```

## Deployment - Hardhat Ignition

To deploy the smart contracts, we have created scripts located in the `ignition` folder.

Before deploying, you should set the values in the `Configurations.json` file. These values represent some configurations for the smart contracts. The following is a description for each one:

- **VRF** - [https://chain.link/vrf](https://chain.link/vrf)
  - `subId`: The VRF subscription ID.
  - `coordinatorAddress`: The VRF coordinator address for the chain you are deploying on.
  - `coordinatorKey`: The VRF key.
- **Functions** - [https://chain.link/functions](https://chain.link/functions)
  - `routerAddress`: The functions router for the chain you are deploying on.
  - `donID`: The DON ID for the chain you are deploying on.
  - `donName`: The DON name for the chain you are deploying on.
  - `gasLimit`: The gas limit for the transactions performed by the functions smart contract.
  - `subscriptionId`: Your functions subscription ID.
  - `encryptedSecretsUrls`: The URL containing the secrets JSON for the functions service to invoke the exposed API.
- **Automation** - [https://chain.link/automation](https://chain.link/automation)
  - `runGameForwarder`: The forwarded address, ensuring that only the automation service calls the game main loop.
  - `setWaveForwarded`: The forwarded address, ensuring that only the automation service sets a new wave at a 6-hour interval.
- **Price Feed** - [https://chain.link/data-feeds](https://chain.link/data-feeds)
  - `AvaxUSD`: The address for the AVAX to USD aggregator on the chain you are deploying on.
- **Roles**: This does not need to be changed and is used to set the roles on the solution's smart contracts.
- **SurfGameConfig**: This holds some configurations for the surf game.
  - `surfForecastLibAddress`: The address of forecast lib, no need to define unless you want to reuse a lib already deployed. Check SurfGame ignition module line 10
  - `surferCollectionAddress`: The address of the collection representing the surfer NFT in the surf game.
  - `surfboardCollectionAddress`: The address of the collection representing the surfboard NFT in the surf game.
- **DeployerAddress**: The wallet executing the deploy.
- **Admins**: A list of admin wallets that will need permission to interact with the contracts. In our solution, this is the wallet deploying the NFT generator.

Once all of this is set, you can deploy it in various modules. To run each module, use the following command:

```bash
npx hardhat ignition deploy ignition/modules/NameOfTheModule.js --network fuji
```

### Main Modules

- **Passes**: Run this to set up the pass NFT, which will be needed to deploy new instances of collections.
  - **Dependencies**: PassManager and RandomManager
- **ShopManager**: Run this to deploy a shop manager capable of selling any new NFT deployed.
  - **Note**: The system creating the NFTs will need to grant the necessary roles to the shop manager.
- **BaseContracts**: Aggregates ShopManager and PassManager, which are the basis for collection management.
- **SurfGame**: Run this module to deploy the surf game.
  - **Dependencies**: SurfForecastService
- **GameSetup**: This should be run last, as it sets the forwarder addresses with the addresses obtained from Chainlink automation services after deploying the surf game.

## Additional Information

There are additional scripts created to help manage the ecosystem. All these utilities are located under the `scripts` folder.

### Admin Scripts

In the `admin` folder, there is a script that allows us to send the ABI, addresses, and other configurations of the deployed smart contracts to our server running the frontend app. This helps streamline the entire process and speeds up development.

### Functions Scripts

In the `functions` folder, the `gen-offchain-data.js` script generates the secrets file and the secrets URL that will be used when interacting with the Chainlink function.
