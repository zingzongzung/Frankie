const {} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { expect } = require("chai");
const { ethers } = require("hardhat");

//npx hardhat test ./test/Common.js
describe("Common", function () {
  describe("Signature", function () {
    it("Can sign a message using a string, a number and a bytes and verifies it on smart contract", async function () {
      const [owner, otherAccount] = await ethers.getSigners();
      const SignatureVerifier = await ethers.getContractFactory(
        "TestSignatureVerifier"
      );
      const signatureVerifier = await SignatureVerifier.deploy();

      const aString = "teste";
      const aNumber = 13;
      const aBytes32 = ethers.encodeBytes32String("A Random string");

      const messageToSign = ethers.solidityPackedKeccak256(
        ["string", "uint256", "bytes32"],
        [aString, aNumber, aBytes32]
      );

      let value = [];
      for (let i = 2; i < messageToSign.length; i = i + 2) {
        let current = "0x" + messageToSign.substring(i, i + 2);
        value.push(current);
      }

      const signatureTest = await owner.signMessage(new Uint8Array(value));

      const signatureVerified = await signatureVerifier.verifiySignature(
        owner,
        signatureTest,
        aString,
        aNumber,
        aBytes32
      );

      const signatureNotVerified = await signatureVerifier.verifiySignature(
        otherAccount,
        signatureTest,
        aString,
        aNumber,
        aBytes32
      );

      expect(
        signatureVerified,
        "The signature from owner should have been verified "
      ).to.equal(true);

      expect(
        signatureNotVerified,
        "The signature from otherAccount should not have been verified "
      ).to.equal(false);
    });

    it("Can sign a message using a string, a number  and verifies it on smart contract", async function () {
      const [owner, otherAccount] = await ethers.getSigners();
      const SignatureVerifier = await ethers.getContractFactory(
        "TestSignatureVerifier"
      );
      const signatureVerifier = await SignatureVerifier.deploy();

      const aString = "teste";
      const aNumber = 13;

      const messageToSign = ethers.solidityPackedKeccak256(
        ["uint256", "string"],
        [aNumber, aString]
      );

      let value = [];
      for (let i = 2; i < messageToSign.length; i = i + 2) {
        let current = "0x" + messageToSign.substring(i, i + 2);
        value.push(current);
      }

      const signatureTest = await owner.signMessage(new Uint8Array(value));

      const signatureVerified =
        await signatureVerifier.verifiySignatureFromString(
          owner,
          signatureTest,
          aNumber,
          aString
        );

      const signatureNotVerified =
        await signatureVerifier.verifiySignatureFromString(
          otherAccount,
          signatureTest,
          aNumber,
          aString
        );

      expect(
        signatureVerified,
        "The signature from owner should have been verified "
      ).to.equal(true);

      expect(
        signatureNotVerified,
        "The signature from otherAccount should not have been verified "
      ).to.equal(false);
    });

    it("Can sign a message using a bytes32, a number  and verifies it on smart contract", async function () {
      const [owner, otherAccount] = await ethers.getSigners();
      const SignatureVerifier = await ethers.getContractFactory(
        "TestSignatureVerifier"
      );
      const signatureVerifier = await SignatureVerifier.deploy();

      const aNumber = 13;
      const aBytes32 = ethers.encodeBytes32String("A Random string");

      const messageToSign = ethers.solidityPackedKeccak256(
        ["uint256", "bytes32"],
        [aNumber, aBytes32]
      );

      let value = [];
      for (let i = 2; i < messageToSign.length; i = i + 2) {
        let current = "0x" + messageToSign.substring(i, i + 2);
        value.push(current);
      }

      const signatureTest = await owner.signMessage(new Uint8Array(value));

      const signatureVerified =
        await signatureVerifier.verifiySignatureFromBytes32(
          owner,
          signatureTest,
          aNumber,
          aBytes32
        );

      const signatureNotVerified =
        await signatureVerifier.verifiySignatureFromBytes32(
          otherAccount,
          signatureTest,
          aNumber,
          aBytes32
        );

      expect(
        signatureVerified,
        "The signature from owner should have been verified "
      ).to.equal(true);

      expect(
        signatureNotVerified,
        "The signature from otherAccount should not have been verified "
      ).to.equal(false);
    });
  });
});
