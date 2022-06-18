const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the accounts: ${deployer.address}`);

  const balance = await deployer.getBalance();
  console.log(`Account Balance: ${balance.toString()}`);

  const Deposit = await ethers.getContractFactory("DepositManager");
  const deposit = await upgrades.deployProxy(Deposit, { kind: "uups" });

  console.log(`Deposit Contract deployed at : ${deposit.address}`);
  const Lighthouse = await ethers.getContractFactory("Lighthouse");

  const lighthouse = await upgrades.deployProxy(Lighthouse, [deposit.address], {
    kind: "uups",
  });

  console.log(`Lighthouse Contract deployed at : ${lighthouse.address}`);

  const Billing = await ethers.getContractFactory("Billing");

  const billing = await upgrades.deployProxy(Billing, [], {
    kind: "uups",
  });

  console.log(`Billing Contract deployed at : ${billing.address}`);

  const LHNFT = await ethers.getContractFactory("LHNFToken");

  const lhnft = await upgrades.deployProxy(LHNFT, [], {
    kind: "uups",
  });

  console.log(`LightHouseNft Contract deployed at : ${lhnft.address}`);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
