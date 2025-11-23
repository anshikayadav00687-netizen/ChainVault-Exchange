const { ethers } = require("hardhat");

async function main() {
  const ChainVaultExchange = await ethers.getContractFactory("ChainVaultExchange");
  const chainVaultExchange = await ChainVaultExchange.deploy();

  await chainVaultExchange.deployed();

  console.log("ChainVaultExchange contract deployed to:", chainVaultExchange.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
