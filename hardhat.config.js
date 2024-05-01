require("@nomicfoundation/hardhat-toolbox");

// Ensure your configuration variables are set before executing the script
const { vars } = require("hardhat/config");

// Go to https://infura.io, sign up, create a new API key
// in its dashboard, and add it to the configuration variables
//npx hardhat vars set INFURA_API_KEY
const INFURA_API_KEY = vars.get("INFURA_API_KEY");

// Add your Sepolia account private key to the configuration variables
// To export your private key from Coinbase Wallet, go to
// Settings > Developer Settings > Show private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Beware: NEVER put real Ether into testing accounts
//npx hardhat vars set FUJI_PRIVATE_KEY
const FUJI_PRIVATE_KEY = vars.get("FUJI_PRIVATE_KEY");

module.exports = {
  solidity: "0.8.24",
  networks: {
    fuji: {
      url: `https://avalanche-fuji.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [FUJI_PRIVATE_KEY],
    },
  },
};
