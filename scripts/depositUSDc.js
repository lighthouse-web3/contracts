const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the accounts: ${deployer.address}`);

  const balance = await deployer.getBalance();
  console.log(`Acccount Balance: ${balance.toString()}`);

  const LendAssets = await ethers.getContractAt(
    "LendAssets",
    "0x2d22817D51a31e32555964c964B75Ef725Ee66E8",deployer
  );

  var tx= await LendAssets.supplyAsset(
    "0x9aa7fEc87CA69695Dd1f879567CcF49F3ba417E2",
    deployer.address,
    "20000000000000",
    deployer.address,
    0
  );
  console.log(await tx.wait())
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
