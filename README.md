# NFT Forge - Chainlink Hackaton

This project represents a different way for defining NFT Collections and algorithms to mint Random NFTs from that collection using chainlink tools.

1 The project is divided in multiple steps.

- Infrastructure
- Infrastructure roles
- The contracts that will be deployed by the front facing portal
- The operations to populate the collection
- The permissions needed to set on those newly deployed collections

2 Infrastructure

- Pass NFT
- Pass Manager
- Random Manager
- Shop Manager
- Game Manager

Run the following command to deploy the infrastructure

```shell
npx hardhat ignition deploy ignition/modules/01_DeployInfrastructure.js --network fuji --reset
```

hardhat.config.js
npx hardhat vars set INFURA_API_KEY
npx hardhat vars set FUJI_PRIVATE_KEY
