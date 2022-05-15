import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
// import verify from "../helper-functions"
// import { networkConfig, developmentChains } from "../helper-hardhat-config"

const deployGovernanceToken: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("----------------------------------------------------");
  log("Deploying GovernanceToken and waiting for confirmations...");
  const lighthouseGovernanceToken = await deploy("LighthouseGovernanceToken", {
    from: deployer,
    args: [],
    log: true,
    // we need to wait if on a live network so we can verify properly
    // waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  });
};

const delegate = async (
  lighthouseGovernanceTokenAddress: string,
  delegatedAccount: string
) => {
  const lighthouseGovernanceToken = await ethers.getContractAt(
    "LighthouseGovernanceToken",
    lighthouseGovernanceTokenAddress
  );
  const transactionResponse = await lighthouseGovernanceToken.delegate(
    delegatedAccount
  );
  await transactionResponse.wait(1);
  console.log(
    `Checkpoints: ${await lighthouseGovernanceToken.numCheckpoints(
      delegatedAccount
    )}`
  );
};

export default deployGovernanceToken;
deployGovernanceToken.tags = ["all", "governor"];
