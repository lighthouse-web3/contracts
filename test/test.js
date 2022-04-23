const { expect } = require("chai");
const { ethers } = require("hardhat");

let Lighthouse, lighthouse, Deposit, deposit, owner,StableCoin,stableCoin;

beforeEach(async () => {
  [owner] = await ethers.getSigners();
  owner = owner.address;

  Deposit = await ethers.getContractFactory("DepositManager");
  deposit = await Deposit.deploy();

  Lighthouse = await ethers.getContractFactory("Lighthouse");
  lighthouse = await Lighthouse.deploy(deposit.address);

  StableCoin = await ethers.getContractFactory("Dai");
  stableCoin = await StableCoin.deploy();

  await stableCoin.faucet(owner,1000);

  // set the manager of the deposit contract;

  await deposit.addCoin('DAI', stableCoin.address);

  await deposit.changeManager(lighthouse.address);


  console.log(`Owner Address : ${owner}`);
  console.log(`Lighthouse Contract deployed at : ${lighthouse.address}`);
  console.log(`Deposit Contract deployed at : ${deposit.address}`);
});

describe("LighthouseContract", () => {
  // it("Should set the right owner", async () => {
  //   expect(await lighthouse.owner()).to.equal(owner);
  // });

  // it("Lighthouse Contract should be the manager of the deposit", async() => {
  //   expect(await deposit.manager()).to.equal(lighthouse.address);
  // });

  // // it("Lighthouse contract address should be whitelisted", async () => {
  // //   expect(await deposit.checkWhiteListAdresses(lighthouse.address)).to.equal(
  // //     true
  // //   );
  // // });

  // it("On each store update the value of data cap", async () => {
  //   await deposit.updateAvailableStorage(owner, 1000);
  //   // await deposit.updateStorage(owner, 100, 'abcd');

  //   const cid = "cid",
  //     config = "config",
  //     filename = "filename",
  //     filesize = 100;
  //   await lighthouse.store(cid, config, filename, filesize);
  //   const storageUser = await deposit.storageList(owner);

  //   console.log(` storage information of User : ${storageUser}`);
  // });

  // it("checking bundles", async () => {
  //   await deposit.updateAvailableStorage(
  //     "0x4932b72f8F88e741366a30aa27492aFEd143A5E1",
  //     1000000000
  //   );

  //   const cid_bundles = [...Array(1000).keys()].fill("cid", 0, 1000);
  //   const config = [...Array(1000).keys()].fill("config", 0, 1000);
  //   const users = [...Array(1000).keys()].fill(
  //     "0x4932b72f8F88e741366a30aa27492aFEd143A5E1",
  //     0,
  //     1000
  //   );
  //   const fileName = [...Array(1000).keys()].fill("fileName", 0, 1000);
  //   const fileSize = [...Array(1000).keys()];
  //   const timestamps = [...Array(1000).keys()];

  //   const structarr = [];
  //   // structarr.push([users[0],cid_bundles[0],config[0],fileName[0],fileSize[0],timestamps[0]]);
  //   // structarr.push([users[0],cid_bundles[1],config[1],fileName[1],fileSize[1],timestamps[1]]);

  //   // await lighthouse.bundleStore(structarr);

  //   for (let i = 0; i < cid_bundles.length; ++i) {
  //     structarr.push([
  //       users[i],
  //       cid_bundles[i],
  //       config[i],
  //       fileName[i],
  //       fileSize[i],
  //       timestamps[i],
  //     ]);
  //   }
  //   console.log(structarr);
  //   let chunk = 100;
  //   const length = structarr.length;
  //   console.log(length);
  //   for (let i = 0; i < length; i += chunk) {
  //     const chunkarr = structarr.slice(i, i + chunk);
  //     await lighthouse.bundleStore(chunkarr);
  //   }
  // });

  // it("only Manager or owner could call the updateStoragefunctions", async () => {
  //   await deposit.updateAvailableStorage(owner,1000);
  // });

  // it("Adding and removing Coins", async () => {

  // });

  // it("Adding deposit", async()=>{
  //   await deposit.addDeposit('DAI');
  // });




});