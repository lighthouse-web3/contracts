const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the accounts: ${deployer.address}`);

  const balance = await deployer.getBalance();
  console.log(`Account Balance: ${balance.toString()}`);

  const LightHouseNftContract = await ethers.getContractFactory("LHNFToken");
  //   let LightHouseNft = await upgrades.deployProxy(LightHouseNftContract, [], {
  //     kind: "uups",
  //   });
  const LightHouseNft = await ethers.getContractAt("LHNFToken", "0x219624332F3c53d47817b9c83Da67C0A53a4c285", deployer);

  const txResponse = await LightHouseNft.safeMint(
    "0x9a40b8EE3B8Fe7eB621cd142a651560Fa7dF7CBa",
    "https://avatars.githubusercontent.com/u/46370698?v=4",
  );
  const txReceipt = await txResponse.wait();
  console.log(txReceipt);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
