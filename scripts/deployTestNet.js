const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the accounts: ${deployer.address}`);

  const balance = await deployer.getBalance();
  console.log(`Acccount Balance: ${balance.toString()}`);

  const Deposit = await ethers.getContractFactory(
    "DepositManager"
  );
  const deposit = await Deposit.deploy();

  const Lighthouse = await ethers.getContractFactory(
    "Lighthouse"
  );
  const lighthouse = await Lighthouse.deploy(deposit.address);
  console.log(`Lighthouse Contract deployed at : ${lighthouse.address}`);
  console.log(`Deposit Contract deployed at : ${deposit.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
