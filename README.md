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

3 Infrastructure Roles

- Grant Roles to PassManager
- Grant Roles to NFT

Run the following command to set the infrastructure roels

```shell
npx hardhat ignition deploy ignition/modules/02_SetInfrastructureRoles.js --network fuji
```

4 Deploy Collections

- This step is not mandatory, but if run will deploy an example collection

Run the following command to set the infrastructure roels

```shell
npx hardhat ignition deploy ignition/modules/03_DeployCollection.js --network fuji
```

4 Setup Collection Permissions

- This step is only mandatory if step 3 was ran.

Run the following command to set the infrastructure roels

```shell
npx hardhat ignition deploy ignition/modules/04_SetCollectionRoles.js --network fuji
```
