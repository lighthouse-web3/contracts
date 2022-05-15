import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { networkConfig, developmentChains } from "../configHardhat";
import { ethers } from "hardhat";

const deployLendAssets: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("----------------------------------------------------");
  log("Deploying LendAssets and waiting for confirmations...");
  const LendAssets = await deploy("LendAssets", {
    from: deployer,
    args: ["0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6"],
    log: true,
    // we need to wait if on a live network so we can verify properly
    //waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });
  log(`LendAssets at ${LendAssets.address}`);
  const LendAssetsContract = await ethers.getContractAt(
    "LendAssets",
    LendAssets.address
  );
  const timeLock = await ethers.getContract("PresidentialLock");
  const transferTx = await LendAssetsContract.transferOwnership(
    timeLock.address
  );
  await transferTx.wait(1);
};

export default deployLendAssets;
deployLendAssets.tags = [ "LendAssets"];
