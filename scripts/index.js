const {
  generateOffchainSecretsFile,
} = require("./functions/gen-offchain-data.js");
require("@chainlink/env-enc").config();

//secrets + secrets url
generateOffchainSecretsFile(
  { apiKey: process.env.API_KEY },
  "https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/offchain-secrets.json"
).catch((e) => {
  console.error(e);
  process.exit(1);
});
