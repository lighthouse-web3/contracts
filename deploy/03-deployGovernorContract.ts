import { HardhatRuntimeEnvironment } from "hardhat/types"
import { DeployFunction } from "hardhat-deploy/types"
import {
  networkConfig,
  QUORUM_PERCENTAGE,
  VOTING_PERIOD,
  VOTING_DELAY,
} from "../configHardhat"

const deployGovernorContract: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  // @ts-ignore
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, log, get } = deployments
  const { deployer } = await getNamedAccounts()
  const governanceToken = await get("LighthouseGovernanceToken")
  const presidentialLock = await get("PresidentialLock")

  log("----------------------------------------------------")
  log("Deploying GovernorContract and waiting for confirmations...")
  const governorContract = await deploy("LighthouseGovernor", {
    from: deployer,
    args: [
      governanceToken.address,
      presidentialLock.address,
      VOTING_PERIOD,
      VOTING_DELAY,
    ],
    log: true,
    // we need to wait if on a live network so we can verify properly
    //waitConfirmations: networkConfig[network.name].blockConfirmations || 1,
  })
  log(`LighthouseGovernorContract at ${governorContract.address}`)
}

export default deployGovernorContract
deployGovernorContract.tags = ["all", "governor"]