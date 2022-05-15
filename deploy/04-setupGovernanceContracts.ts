import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ADDRESS_ZERO } from "../configHardhat";
import { ethers } from "hardhat";

const setupContracts: DeployFunction = async function (
  hre: HardhatRuntimeEnvironment
) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre;
  const { log } = deployments;
  const { deployer } = await getNamedAccounts();
  const governanceToken = await ethers.getContract("LighthouseGovernanceToken", deployer);
  const presidentialLock = await ethers.getContract("PresidentialLock", deployer);
  const governor = await ethers.getContract("LighthouseGovernor", deployer);

  log("----------------------------------------------------");
  log("Setting up contracts for roles...");
  // would be great to use multicall here...
  const proposerRole = await presidentialLock.PROPOSER_ROLE();
  const executorRole = await presidentialLock.EXECUTOR_ROLE();
  const adminRole = await presidentialLock.TIMELOCK_ADMIN_ROLE();

  const proposerTx = await presidentialLock.grantRole(proposerRole, governor.address);
  await proposerTx.wait(1);
  const executorTx = await presidentialLock.grantRole(executorRole, ADDRESS_ZERO);
  await executorTx.wait(1);
  const revokeTx = await presidentialLock.revokeRole(adminRole, deployer);
  await revokeTx.wait(1);
};

export default setupContracts;
setupContracts.tags = ["all", "setup"];
