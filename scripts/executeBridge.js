const { ethers } = require("hardhat");
const { connect } = require("http2");
const USDC_ON_FANTOM = "0x1717A0D5C8705EE89A8aD6E808268D6A826C97A4";
const CHAIN_ID_POLYGON = "10011";
const RenRouter = "0x817436a076060D158204d955E5403b6Ed0A5fac0";
const _amount = 1e10;
//fantom
async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(`Deploying contracts with the accounts: ${deployer.address}`);
  const balance = await deployer.getBalance();
  console.log(`Account Balance: ${balance.toString()}`);

  const bridger = await ethers.getContractAt(
    "Bridger",
    "0xF6F40D56eCfc41bC6f6Ce998CBF152F61FfFE6CC",
    deployer
  );

  const USDC = await ethers.getContractAt("Dai", USDC_ON_FANTOM, deployer);
  let tx = await bridger.getSwapFee(CHAIN_ID_POLYGON, RenRouter);
  const transfee = tx.toString();
  console.log(await USDC.balanceOf(deployer.address));

  tx = await USDC.approve(bridger.address, _amount);
  tx = await tx.wait();

  tx = await USDC.allowance(deployer.address, bridger.address);
  console.log(transfee);
  //console.log(tx);
  //   uint16 chain_Id,
  //   address _asset,
  //   uint256 _amount,
  //   address[] memory _vaultTo
  tx = await bridger.swap(
    CHAIN_ID_POLYGON,
    USDC_ON_FANTOM,
    _amount,
    RenRouter,
    {
      value: `${parseInt(parseInt(transfee) * 1.5)}`,
    }
  );
  tx = await tx.wait();
  console.log(tx);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
