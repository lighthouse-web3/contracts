const USDT = "0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02";
const Router = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the accounts: ${deployer.address}`);

  const balance = await deployer.getBalance();
  console.log(`Acccount Balance: ${balance.toString()}`);

  const swap = await ethers.getContractFactory("SwapClient");
  //  const Swap = await upgrades.upgradeProxy("0x23757b4053DE55b6c3f53bF584F9E80e85D318cE", swap, { kind: "uups" });

  const Swap = await ethers.getContractAt("SwapClient", "0x23757b4053DE55b6c3f53bF584F9E80e85D318cE", deployer);
  console.log(`Swap Contract deployed at : ${Swap.address}`);

  let tx = await Swap.swapTokenToToken(
    USDT,
    deployer.address,
    `${0.001 * 1e18}`,
    `${1 * 1e20}`,
    parseInt(Date.now() / 1000) + 600,
  );
  console.log(await tx.wait());
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
