import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { networkConfig, developmentChains, MIN_DELAY } from "../configHardhat";

const deployPresidentialLock: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("----------------------------------------------------");
  log("Deploying PresidentialLock and waiting for confirmations...");
  const PresidentialLock = await deploy("PresidentialLock", {
    from: deployer,
    args: [MIN_DELAY, [], []],
    log: true,
    // we need to wait if on a live network so we can verify properly
    waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });
  log(`PresidentialLock at ${PresidentialLock.address}`);
};

export default deployPresidentialLock;
deployPresidentialLock.tags = ["all", "presidentialLock"];
