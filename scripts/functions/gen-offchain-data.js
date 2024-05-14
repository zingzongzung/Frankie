const fs = require("fs");
const path = require("path");
const { SecretsManager } = require("@chainlink/functions-toolkit");
const ethers = require("ethers");
require("@chainlink/env-enc").config();

const generateOffchainSecretsFile = async (secrets, secretsURL) => {
	// hardcoded for Polygon Mumbai
	// const routerAddress = "0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C";
	// const donId = "fun-polygon-mumbai-1";
	//Fuji
	const routerAddress = "0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0";
	const donId = "fun-avalanche-fuji-1";

	// Initialize ethers signer and provider to interact with the contracts onchain
	//Run this to set private key npx env-enc set
	const privateKey = process.env.PRIVATE_KEY; // fetch PRIVATE_KEY

	if (!privateKey) throw new Error("private key not provided - check your environment variables");

	const rpcUrl = process.env.FUJI_RPC_URL;

	if (!rpcUrl) throw new Error(`rpcUrl not provided  - check your environment variables`);

	//const provider = new ethers.JsonRpcProvider(rpcUrl);
	const provider = new ethers.providers.JsonRpcProvider(rpcUrl);

	const wallet = new ethers.Wallet(privateKey);
	const signer = wallet.connect(provider); // create ethers signer for signing transactions

	// Initialize SecretsManager instance
	const secretsManager = new SecretsManager({
		signer: signer,
		functionsRouterAddress: routerAddress,
		donId: donId,
	});
	await secretsManager.initialize();
	// secrets file path
	const rootDir = process.cwd();
	const secretsFilePath = path.resolve(rootDir, "offchain-secrets.json");

	const secretsUrklsFilePath = path.resolve(rootDir, "offchain-Urls.json");

	// Encrypt secrets
	const encryptedSecretsObj = await secretsManager.encryptSecrets(secrets);

	// Write the JSON string to a file
	try {
		fs.writeFileSync(secretsFilePath, JSON.stringify(encryptedSecretsObj));
		console.log("Encrypted secrets object written to " + secretsFilePath);
	} catch (error) {
		console.error(error);
	}

	const encryptedSecretsUrls = await secretsManager.encryptSecretsUrls([secretsURL]);

	// Write the JSON string to a file
	try {
		fs.writeFileSync(secretsUrklsFilePath, JSON.stringify(encryptedSecretsUrls));
		console.log("Encrypted secrets object written to " + secretsUrklsFilePath);
	} catch (error) {
		console.error(error);
	}
};

module.exports = {
	generateOffchainSecretsFile,
};
