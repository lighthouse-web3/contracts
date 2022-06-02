const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers, upgrades } = require("hardhat");

let billing, stableCoin, owner, account2, account3, account4;
beforeEach(async () => {
  [owner, account2, account3, account4] = await ethers.getSigners();
  owner = owner.address;

  const Billing = await ethers.getContractFactory("Billing");
  billing = await upgrades.deployProxy(Billing, { kind: "uups" });

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
});

describe("Billing Contract", () => {
  it("Should set the right owner", async () => {
    expect(await billing.owner()).to.equal(owner);
  });

  it("Should CreateSystemSubscription", async () => {
    let tx = await billing.createSystemSubscription({
      frequencyOfDeduction: 4,
      deductionIN: 2,
      amount: 3.5 * 1e6,
      isActive: true,
      code: "0x00000000000000",
    });
    tx = await tx.wait();

    let data = await billing.contractSubscriptions(0);
    expect(data).to.include.all.keys([
      "frequencyOfDeduction",
      "deductionIN",
      "amount",
      "isActive",
      "code",
    ]);
    expect(data).to.have.property("frequencyOfDeduction", 4);
    expect(data).to.have.property("deductionIN", 2);
    expect(data.amount.toString()).to.equal("3500000");
    expect(data).to.have.property("isActive", true);
    expect(data).to.have.property("code", "0x00000000000000");
  });

  it("Should add accepted token ", async () => {
    let tx = await billing.addStableCoin(stableCoin.address, {
      rate: 0.997 * 1e6,
      isActive: true,
    });
    tx = await tx.wait();
    let data = await billing.stableCoinStatus(stableCoin.address);
    expect(data).to.include.all.keys(["isActive", "rate"]);
    expect(data.rate.toString()).to.equal("997000");
    expect(data).to.have.property("isActive", true);
  });

  it("Should Reject Cost estimations for tokens Not added", async () => {
    let tx = await billing.createSystemSubscription({
      frequencyOfDeduction: 4,
      deductionIN: 2,
      amount: 3.5 * 1e6,
      isActive: true,
      code: "0x00000000000000",
    });
    tx = await tx.wait();
    try {
      data = await billing.getAmountToBeDeducted(stableCoin.address, 0);
      console.log(data);
    } catch (e) {
      expect(e.message).to.include(
        "VM Exception while processing transaction:"
      );
    }
  });

  it("Should get Cost estimations for Subscription", async () => {
    let tx = await billing.createSystemSubscription({
      frequencyOfDeduction: 4,
      deductionIN: 2,
      amount: 3.5 * 1e6,
      isActive: true,
      code: "0x00000000000000",
    });
    tx = await tx.wait();
    tx = await billing.addStableCoin(stableCoin.address, {
      rate: 0.997 * 1e6,
      isActive: true,
    });
    tx = await tx.wait();
    data = await billing.getAmountToBeDeducted(stableCoin.address, 0);
    expect(data.toString()).to.equal("3489500000000000000");
  });

  it("Should fail to active Subscription if insufficient allowance is given ", async () => {
    let tx = await billing.createSystemSubscription({
      frequencyOfDeduction: 2,
      deductionIN: 2,
      amount: 3.5 * 1e6,
      isActive: true,
      code: "0x00000000000000",
    });
    tx = await tx.wait();
    tx = await billing.addStableCoin(stableCoin.address, {
      rate: 0.997 * 1e6,
      isActive: true,
    });
    tx = await tx.wait();
    data = await billing.getAmountToBeDeducted(stableCoin.address, 0);

    try {
      tx = await billing.activateSubscription(0, stableCoin.address);
    } catch (e) {
      expect(e.message).to.include("Increase Allowance to match subscription");
    }
  });

  it("Should active Subscription ", async () => {
    const subData = {
      frequencyOfDeduction: 2,
      deductionIN: 2,
      amount: 3.5 * 1e6,
      isActive: true,
      code: "0x00000000000000",
    };
    let tx = await billing.createSystemSubscription(subData);
    tx = await tx.wait();
    tx = await billing.addStableCoin(stableCoin.address, {
      rate: 0.997 * 1e6,
      isActive: true,
    });
    tx = await tx.wait();
    price = await billing.getAmountToBeDeducted(stableCoin.address, 0);

    stableCoin.approve(
      billing.address,
      `${price * subData.frequencyOfDeduction}`
    );
    tx = await billing.activateSubscription(0, stableCoin.address);
    tx = await billing.isSubscriptionActive(owner);
    tx = await tx.wait();
    expect(tx.events[0].args.active).to.equal(true);
  });

  it("Should reject joining cancel or expired Subscription ", async () => {
    const subData = {
      frequencyOfDeduction: 2,
      deductionIN: 2,
      amount: 3.5 * 1e6,
      isActive: true,
      code: "0x00000000000000",
    };
    let tx = await billing.createSystemSubscription(subData);
    tx = await tx.wait();
    tx = await billing.cancelSystemSubscription(0);
    tx = await tx.wait();
    tx = await billing.addStableCoin(stableCoin.address, {
      rate: 0.997 * 1e6,
      isActive: true,
    });
    tx = await tx.wait();
    price = await billing.getAmountToBeDeducted(stableCoin.address, 0);

    stableCoin.approve(
      billing.address,
      `${price * subData.frequencyOfDeduction}`
    );
    try {
      tx = await billing.activateSubscription(0, stableCoin.address);
    } catch (e) {
      expect(e.message).to.include(
        "VM Exception while processing transaction: reverted with reason string 'this offer has expired'"
      );
    }
  });

  it("Check the status of account that has no subscription", async () => {
    tx = await billing.isSubscriptionActive(account2.address);
    tx = await tx.wait();
    expect(tx.events[0].args.active).to.equal(false);
  });
});
