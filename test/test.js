const { expect } = require("chai");
const { ethers } = require("hardhat");

let Lighthouse,
  lighthouse,
  Deposit,
  deposit,
  owner,
  StableCoin,
  stableCoin,
  account2;

beforeEach(async () => {
  [owner, account2] = await ethers.getSigners();
  owner = owner.address;

  Deposit = await ethers.getContractFactory(
    "contracts/deposit_test/DepositManager.sol:DepositManager"
  );
  deposit = await Deposit.deploy();

  Lighthouse = await ethers.getContractFactory(
    "contracts/lighthouse_test.sol:Lighthouse"
  );
  lighthouse = await Lighthouse.deploy(deposit.address);

  StableCoin = await ethers.getContractFactory("Dai");
  stableCoin = await StableCoin.deploy();

  await stableCoin.faucet(owner, 1000);

  // set the manager of the deposit contract;

  await deposit.addCoin(stableCoin.address, 10 ** 6);

  await deposit.setWhiteListAddr(lighthouse.address, true);

  console.log(`Owner Address : ${owner}`);
  console.log(`Lighthouse Contract deployed at : ${lighthouse.address}`);
  console.log(`Deposit Contract deployed at : ${deposit.address}`);
});

describe("LighthouseContract", () => {
  it("Should set the right owner", async () => {
    expect(await lighthouse.owner()).to.equal(owner);
  });

  it("On each store update the value of data cap", async () => {
    await deposit.updateAvailableStorage(owner, 1000);
    // await deposit.updateStorage(owner, 100, 'abcd');

    const cid = "cid",
      config = "config",
      filename = "filename",
      filesize = 100;
    await lighthouse.store(cid, config, filename, filesize);
    const storageUser = await deposit.storageList(owner);
    
    // @todo test case should check if final available storage is 900
    console.log(` storage information of User : ${storageUser}`);
  });

  it("Adding deposit", async () => {
    //approve coins
    var data = await stableCoin.approve(deposit.address, 10);
    data = await data.wait();
    await deposit.addDeposit(stableCoin.address, 10);

    // @todo test should check the balance of the deposit contract after calling this function
    // @todo make another test which test the new available storage of the user after deposit is complete
  });
  it("checking bundles", async () => {
    await deposit.updateAvailableStorage(
      "0x4932b72f8F88e741366a30aa27492aFEd143A5E1",
      1000000000
    );

    const cid_bundles = [...Array(100).keys()].fill("cid", 0, 1000);
    const config = [...Array(100).keys()].fill("config", 0, 1000);
    const users = [...Array(100).keys()].fill(
      "0x4932b72f8F88e741366a30aa27492aFEd143A5E1",
      0,
      1000
    );
    const fileName = [...Array(100).keys()].fill("fileName", 0, 1000);
    const fileSize = [...Array(100).keys()];
    const timestamps = [...Array(100).keys()];

    const structarr = [];
    // structarr.push([users[0],cid_bundles[0],config[0],fileName[0],fileSize[0],timestamps[0]]);
    // structarr.push([users[0],cid_bundles[1],config[1],fileName[1],fileSize[1],timestamps[1]]);

    // await lighthouse.bundleStore(structarr);

    for (let i = 0; i < cid_bundles.length; ++i) {
      structarr.push([
        users[i],
        cid_bundles[i],
        config[i],
        fileName[i],
        fileSize[i],
        timestamps[i],
      ]);
    }
    let chunk = 100;
    const length = structarr.length;
    for (let i = 0; i < length; i += chunk) {
      const chunkarr = structarr.slice(i, i + chunk);
      await lighthouse.bundleStore(chunkarr);
    }
  });

  it("only Manager or owner could call the updateStoragefunctions", async () => {
    await deposit.updateAvailableStorage(owner, 1000);
    // @todo Make a test for a manager address as well
    // @todo Make a test for an non mangerOrOwner Address
  });

  it("removing Coin and expect failure after coin has been removed", async () => {
    var data = await deposit.removeCoin(stableCoin.address);
    data = await data.wait();
    //approve coins
    try {
      data = await stableCoin.approve(deposit.address, 10);
      data = await data.wait();
      data = await deposit.addDeposit(stableCoin.address, 10);
    } catch (e) {
      expect(e.message).to.equal(
        "VM Exception while processing transaction: reverted with reason string 'suggest coin to Admin'"
      );
    }
  });

  it("removing Coin and expect failure on duplicate removal", async () => {
    var data = await deposit.removeCoin(stableCoin.address);
    data = await data.wait();
    //approve coins
    try {
      var data = await deposit.removeCoin(stableCoin.address);
      data = await data.wait();
    } catch (e) {
      expect(e.message).to.equal(
        "VM Exception while processing transaction: reverted with reason string 'coin already disabled'"
      );
    }
  });

  it("Reject Non Approved Addresses", async () => {
    try {
      await deposit.connect(account2).updateAvailableStorage(owner, 1000);
      throw new Error("Invalid");
    } catch (err) {
      expect(err.message).to.equal(
        "VM Exception while processing transaction: reverted with reason string 'Account Not Whitelisted'"
      );
    }
  });

  it("Accept whitelisted for contracts Marked with the modifier", async () => {
    let tx = await deposit.setWhiteListAddr(account2.address, true);
    tx.wait();
    tx = await deposit
      .connect(account2)
      .updateAvailableStorage(account2.address, 1000);
    tx.wait();
    tx = await deposit.getAvailableSpace(account2.address);
    expect(parseInt(tx)).to.equal(1000);
  });
});
