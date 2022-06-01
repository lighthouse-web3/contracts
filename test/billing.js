const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers, upgrades } = require("hardhat");

let billing;
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

  it("Should CreateSubscription", async () => {
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
});
