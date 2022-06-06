const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

let Lighthouse,
  lighthouse,
  Deposit,
  deposit,
  owner,
  StableCoin,
  stableCoin,
  account2,
  account3,
  account4;

beforeEach(async () => {
  [owner, account2, account3, account4] = await ethers.getSigners();
  owner = owner.address;

  Deposit = await ethers.getContractFactory(
    "contracts/core/DepositManager.sol:DepositManager"
  );
  deposit = await upgrades.deployProxy(Deposit, { kind: "uups" });

  Lighthouse = await ethers.getContractFactory(
    "contracts/core/Lighthouse.sol:Lighthouse"
  );
  lighthouse = await upgrades.deployProxy(Lighthouse, [deposit.address], {
    kind: "uups",
  });

  StableCoin = await ethers.getContractFactory("Dai");
  stableCoin = await StableCoin.deploy();

  await stableCoin.faucet(owner, ethers.utils.parseUnits("1000", "ether"));
  await stableCoin.faucet(
    account2.address,
    ethers.utils.parseUnits("60", "ether")
  );
  await stableCoin.faucet(
    account3.address,
    ethers.utils.parseUnits("300", "ether")
  );

  // set the manager of the deposit contract;

  await deposit.addCoin(stableCoin.address, 10 ** 6);

  await deposit.setWhiteListAddr(lighthouse.address, true);

  // console.log(`Owner Address : ${owner}`);
  // console.log(`Lighthouse Contract deployed at : ${lighthouse.address}`);
  // console.log(`Deposit Contract deployed at : ${deposit.address}`);
});

describe("LighthouseContract", () => {
  it("Should set the right owner", async () => {
    expect(await lighthouse.owner()).to.equal(owner);
  });

  it("On each store update the value of data cap", async () => {
    let tx = await deposit.updateAvailableStorage(account3.address, 1000);
    await tx.wait();

    const cid =
        "0x3fd54831f488a22b28398de0c567a3b064b937f54f81739ae9bd545967f3abab",
      config = "config",
      filename = "filename",
      filesize = 100;
    tx = await lighthouse
      .connect(account3)
      .store(cid, config, filename, filesize);
    await tx.wait();

    // @todo test case should check if final available storage is 900
    tx = await deposit.getAvailableSpace(account3.address);
    expect(tx).to.equal(900);
  });

  it("Adding deposit", async () => {
    let intialBalance = ethers.utils.formatUnits(
      await stableCoin.connect(account3).balanceOf(account3.address),
      "ether"
    );

    let purchaseAmount = ethers.utils.parseUnits("10.0", "ether");
    //approve coins
    var data = await stableCoin
      .connect(account3)
      .approve(deposit.address, purchaseAmount);
    data = await data.wait();

    let balance = await deposit.getAvailableSpace(account3.address);
    expect(balance).to.equal(0);

    await deposit
      .connect(account3)
      .addDeposit(stableCoin.address, purchaseAmount);

    // @todo test should check the balance of the deposit contract after calling this function
    data = +ethers.utils.formatUnits(
      await stableCoin.connect(account3).balanceOf(account3.address),
      "ether"
    );
    expect(data).to.equal(
      intialBalance - ethers.utils.formatUnits(purchaseAmount, "ether")
    );

    // @todo make another test which test the new available storage of the user after deposit is complete
    balance = await deposit.getAvailableSpace(account3.address);
    expect(balance).to.equal(2147483650);
  });
  it("checking bundles", async () => {
    await deposit.updateAvailableStorage(
      "0x4932b72f8F88e741366a30aa27492aFEd143A5E1",
      1000000000
    );

    const cid_bundles = [...Array(100).keys()].fill(
      "0x3fd54831f488a22b28398de0c567a3b064b937f54f81739ae9bd545967f3abaa",
      0,
      1000
    );
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

    await lighthouse.bundleStore(structarr);

    for (let i = 0; i < cid_bundles.length; ++i) {
      structarr.push([
        users[i],
        cid_bundles[i],
        "",
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

  it("test edgeCase", async () => {
    await deposit.updateAvailableStorage(
      "0x4932b72f8F88e741366a30aa27492aFEd143A5E1",
      1e2
    );

    const cid_bundles = [...Array(100).keys()].fill(
      "0x3fd54831f488a22b28398de0c567a3b064b937f54f81739ae9bd545967f3abaa",
      0,
      1e6
    );
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

    await lighthouse.bundleStore(structarr);

    for (let i = 0; i < cid_bundles.length; ++i) {
      structarr.push([
        users[i],
        cid_bundles[i],
        "",
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
    //see "Reject Non Approved Addresses"
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

  it("Valid old Accounts that has been removed from the WhiteList cant access function masked with the Modifier ", async () => {
    let tx = await deposit.setWhiteListAddr(account2.address, true);
    await tx.wait();
    tx = await deposit.setWhiteListAddr(account2.address, false);
    await tx.wait();
    try {
      await deposit.connect(account2).updateAvailableStorage(owner, 1000);
      throw new Error("Invalid");
    } catch (err) {
      expect(err.message).to.equal(
        "VM Exception while processing transaction: reverted with reason string 'Account Not Whitelisted'"
      );
    }
  });

  it("Change Cost Of Storage", async () => {
    const cost = parseInt(1024 ** 3 / 30);
    let tx = await deposit.changeCostOfStorage(cost);
    await tx.wait();

    let newCost = await deposit.costOfStorage();
    expect(newCost).to.equal(cost);
  });

  it("Transfer Tokens Out of the contract", async () => {
    let mintData = ethers.utils.parseUnits("1000", "ether");
    let tx = await stableCoin.faucet(deposit.address, mintData);
    await tx.wait();
    let data = await stableCoin.balanceOf(deposit.address);

    expect(data).to.equal(mintData);

    data = await deposit.transferAmount(
      stableCoin.address,
      account4.address,
      mintData
    );

    data = await stableCoin.balanceOf(deposit.address);

    expect(data).to.equal(0);
  });

  it("Should emit StorageStatusRequest event", async () => {
    await expect(
      lighthouse.requestStorageStatus(
        "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR"
      )
    ).to.emit(lighthouse, "StorageStatusRequest");
  });

  it("Should publish/set Storage Status", async () => {
    const dealId = "1243324";
    let tx = await lighthouse.publishStorageStatus(
      "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR",
      dealId,
      true
    );
    tx = await tx.wait();

    data = await lighthouse.statuses(
      "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR"
    );
    expect(data.active).to.equal(true);
    expect(data.dealIds).to.equal(dealId);
  });
});
