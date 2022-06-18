const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

let Weth, tokenA, tokenB, Factory, Router;

beforeEach(async () => {
  [owner, account2, account3, account4] = await ethers.getSigners();
  owner = owner.address;

  TOKEN = await ethers.getContractFactory("Dai");
  tokenA = await TOKEN.deploy();
  tokenB = await TOKEN.deploy();
  console.log(tokenA.address, tokenB.address);

  WETH = await ethers.getContractFactory("WETH9Mock");
  Weth = await WETH.deploy();

  FACTORY = await ethers.getContractFactory("MockFactory");
  Factory = await FACTORY.deploy();

  ROUTER = await ethers.getContractFactory("MockRouter");
  Router = await ROUTER.deploy(`${Factory.address}`, `${Weth.address}`);
  console.log(Router.address);

  tx = await Factory.createPair(Weth.address, tokenA.address);
  tx = await tx.wait();
  tx = await Factory.createPair(Weth.address, tokenB.address);
  tx = await tx.wait();
  tx = await Factory.createPair(tokenA.address, tokenB.address);
  tx = await tx.wait();

  console.log("firse", await Factory.allPairs(0), await Factory.allPairs(1), await Factory.allPairs(1));

  await tokenA.faucet(owner, ethers.utils.parseUnits("1000", "ether"));
  await tokenB.faucet(owner, ethers.utils.parseUnits("1000", "ether"));

  console.log(await tokenA.balanceOf(owner));

  tx = await Promise.all([
    tokenB.approve(Router.address, ethers.utils.parseUnits("10000000", "ether")),
    tokenA.approve(Router.address, ethers.utils.parseUnits("10000000", "ether")),
  ]);
  tx = await Promise.all([tx[0].wait(), tx[1].wait()]);

  // tx = await Router.addLiquidity(
  //   tokenA.address,
  //   tokenB.address,
  //   `${ethers.utils.parseUnits("100000", "ether")}`,
  //   `${ethers.utils.parseUnits("100000", "ether")}`,
  //   0,
  //   0,
  //   `${account4.address}`,
  //   parseInt(Date.now() / 1000) + 30,
  // );

  // console.log(await tx.wait());
});

describe("Exchange", () => {
  it("test", async () => {
    expect(true).to.equal(true);
  });
});
