const { expect } = require("chai");
const { ethers } = require("hardhat");

let deployer, LendAssets, USDC;

beforeEach(async () => {
  [deployer] = await ethers.getSigners();

    LendAssets = await ethers.getContractAt(
      "LendAssets",
      "0x2d22817D51a31e32555964c964B75Ef725Ee66E8",
      deployer
    );
//   LendAssets = await ethers.getContractFactory("LendAssets");
//   LendAssets = await LendAssets.deploy("0x5343b5bA672Ae99d627A1C87866b8E53F47Db2E6");
  USDC = await ethers.getContractAt(
    "Dai",
    "0x9aa7fEc87CA69695Dd1f879567CcF49F3ba417E2",
    deployer
  );
});

describe("LendingContract", () => {
  it("Should set the right owner", async () => {
    const stakeVal =  ethers.utils.parseUnits("100", "ether");
    const tc = await USDC.approve(LendAssets.address,stakeVal );
    await tc.wait();
    console.log(deployer.address);
    var tx = await LendAssets.supplyAsset(
      "0x9aa7fEc87CA69695Dd1f879567CcF49F3ba417E2",
      deployer.address,
     stakeVal,
      deployer.address,
      0
    );
    console.log(await tx.wait());
  });
});
