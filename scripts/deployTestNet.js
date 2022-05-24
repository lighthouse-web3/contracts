const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the accounts: ${deployer.address}`);

  const balance = await deployer.getBalance();
  console.log(`Acccount Balance: ${balance.toString()}`);

  const Deposit = await ethers.getContractFactory(
    "contracts/DepositManager.sol:DepositManager"
  );
  const deposit = await upgrades.deployProxy(Deposit, { kind: "uups" });

  console.log(`Deposit Contract deployed at : ${deposit.address}`);
  const Lighthouse = await ethers.getContractFactory(
    "contracts/Lighthouse.sol:Lighthouse"
  );

  const lighthouse = await upgrades.deployProxy(Lighthouse, [deposit.address], {
    kind: "uups",
  });

  console.log(`Lighthouse Contract deployed at : ${lighthouse.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
