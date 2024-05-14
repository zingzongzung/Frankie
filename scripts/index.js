const { generateOffchainSecretsFile } = require("./functions/gen-offchain-data.js");

//secrets + secrets url
generateOffchainSecretsFile(
	{ apiKey: "a0226a78-b18b-47d3-b144-4f880080868e" },
	"https://personal-ixqe4210.outsystemscloud.com/NFTMaker_API/offchain-secrets.json"
).catch((e) => {
	console.error(e);
	process.exit(1);
});
