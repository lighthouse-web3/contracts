const { solidity } = require("ethereum-waffle");
const { SignerWithAddress } = require("@nomiclabs/hardhat-ethers/signers");

const { expect, use } = require("chai");
const { ethers, upgrades } = require("hardhat");
const crypto = require("crypto");

use(solidity);

let accounts; // SignerWithAddress[]
let bridgerton; // Bridgerton contract
let vault; // List of vaults
let vaultSecond;
let underlying; // Underlying ERC20 token for the vaults

const USDC_ON_POLYGON = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174";
const USDT_ON_POLYGON = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f";
const USDC_ON_AVALANCHE = "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E";
const STARGATEROUTER = "0x45A01E4e04F14f7A4a6702c74187c5F6222033cd"; // Address of the router on Polygon
// const ETHER = "1000000000000000000";

describe("Bridgerton contract", function () {
  beforeEach(async function () {
    accounts = await ethers.getSigners();

    /** Deploy core contracts **/

    // Deploy Bridgerton contract
    const Bridgerton = await ethers.getContractFactory("Bridgerton");
    bridgerton = await Bridgerton.deploy(STARGATEROUTER);
    await bridgerton.deployed();

    // Deploy ERC20 token for the vaults
    const Token = await ethers.getContractFactory("GT");
    underlying = await Token.deploy(10000000000000);
    await underlying.deployed();

    // Vault creation, a vault is an ERC4626 contract in our case a Savor4626 contract
    const Vault = await ethers.getContractFactory("SavorVault");
    vault = await Vault.deploy(underlying.address, bridgerton.address);
    await vault.deployed();

    // Creation of the second vault
    const VaultSecond = await ethers.getContractFactory("SavorVault");
    vaultSecond = await VaultSecond.deploy(
      underlying.address,
      bridgerton.address
    );
    await vaultSecond.deployed();

    // Checks
    expect(bridgerton.address).to.not.equal(ethers.constants.AddressZero);
    expect(underlying.address).to.not.equal(ethers.constants.AddressZero);
    expect(vault.address).to.not.equal(ethers.constants.AddressZero);
    expect(vaultSecond.address).to.not.equal(ethers.constants.AddressZero);
  });

  describe("Main functions - Integration tests", function () {
    it("Test setVault", async () => {
      await bridgerton.setVault(vault.address);

      // Checks
      expect(await bridgerton.vaults(vault.address)).to.equal(true);
    });

    it("Should revert and fail to setVault", async () => {
      await expect(bridgerton.setVault(ethers.constants.AddressZero)).to.be
        .reverted;
    });

    it("Should fail to setVault as no onlyOwner", async () => {
      await expect(bridgerton.connect(accounts[1]).setVault(vault.address)).to
        .be.reverted;
    });

    it("Add an assets to the Bridgerton", async () => {
      await bridgerton.addAsset(USDC_ON_POLYGON, 1);
      await bridgerton.addAsset(USDT_ON_POLYGON, 2); // check https://stargateprotocol.gitbook.io/stargate/developers/pool-ids for pids
      await bridgerton.addAsset(USDC_ON_AVALANCHE, 1);

      // Checks
      expect(await bridgerton.pids(USDC_ON_POLYGON)).to.equal(1);
      expect(await bridgerton.pids(USDT_ON_POLYGON)).to.equal(2);
      expect(await bridgerton.pids(USDC_ON_AVALANCHE)).to.equal(1);
    });

    it("Should fail to addAsset as no onlyOwner", async () => {
      await expect(bridgerton.connect(accounts[1]).addAsset(USDC_ON_POLYGON)).to
        .be.reverted;
    });

    it("Test sweep function", async () => {
      const initialTokenBalanceSender = await underlying.balanceOf(
        accounts[0].address
      );
      const initialTokenBalanceBridgerton = await underlying.balanceOf(
        bridgerton.address
      );

      // Transfer tokens to the bridgerton contract
      await underlying.transfer(bridgerton.address, 100);
      expect(await underlying.balanceOf(bridgerton.address)).to.equal(100);

      await bridgerton.sweep(underlying.address);

      // Checks
      expect(await underlying.balanceOf(accounts[0].address)).to.equal(
        initialTokenBalanceSender
      );
      expect(await underlying.balanceOf(bridgerton.address)).to.equal(
        initialTokenBalanceBridgerton
      );
    });

    it("Should fail to sweep as no onlyOwner", async () => {
      await expect(bridgerton.connect(accounts[1]).sweep(underlying.address)).to
        .be.reverted;
    });

    it("Should fail to sweep as no onlyOwner", async () => {
      await expect(bridgerton.connect(accounts[1]).sweep(underlying.address)).to
        .be.reverted;
    });

    it("Should change stargate Router", async () => {
      const previousRouter = await bridgerton.stargateRouter();

      await bridgerton._changeStargateRouter(
        "0x8731d54E9D02c286767d56ac03e8037C07e01e98"
      );

      // Checks
      expect(await bridgerton.stargateRouter()).to.not.equal(previousRouter);
    });

    it("Should revert fail to change stargate Router", async () => {
      await expect(
        bridgerton._changeStargateRouter(ethers.constants.AddressZero)
      ).to.be.revertedWith("Must be valid address");
    });

    it("Should fail to change stargate Router as no onlyOwner", async () => {
      await expect(
        bridgerton
          .connect(accounts[1])
          ._changeStargateRouter(ethers.constants.AddressZero)
      ).to.be.reverted;
    });

    it("Should revert fail to change stargate Router", async () => {
      await expect(
        bridgerton._changeStargateRouter(ethers.constants.AddressZero)
      ).to.be.revertedWith("Must be valid address");
    });

    it("Should emit sgReceived event", async () => {
      const chainId = 137;
      const srcAddress = accounts[0].address;
      const amountLD = ethers.constants.One;
      await expect(
        bridgerton.sgReceive(
          chainId,
          srcAddress,
          ethers.constants.One,
          underlying.address,
          amountLD,
          "0x"
        )
      ).to.emit(bridgerton, "sgReceived");
    });

    // TODO Revert exception is missing, check on testnet
    // it.only("Should estimate cross chain gas fee", async () => {
    //   console.log(
    //     await bridgerton._externalGetSwapFee(
    //       250,
    //       accounts[1].address,
    //       vaultSecond.address
    //     )
    //   );
    // });
  });
});
