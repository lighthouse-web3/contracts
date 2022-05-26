const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the accounts: ${deployer.address}`);

  const balance = await deployer.getBalance();
  console.log(`Account Balance: ${balance.toString()}`);

  const Bridger = await ethers.getContractFactory("Bridger");
  const bridger = await upgrades.deployProxy(
    Bridger,
    [
      "0x82A0F5F531F9ce0df1DF5619f74a0d3fA31FF561",
      ["0x1717A0D5C8705EE89A8aD6E808268D6A826C97A4"],
      [1],
    ],
    { kind: "uups" }
  );

  console.log(`Bridge Contract deployed at : ${bridger.address}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
