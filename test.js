const { ethers } = require("hardhat");

function testDecodeBytes(bytesData) {
  console.log(ethers.toUtf8String(bytesData));
}
testDecodeBytes("0x74657374652d6b6579");
