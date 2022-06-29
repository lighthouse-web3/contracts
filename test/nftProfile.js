const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers, upgrades } = require("hardhat");

let nftProfile;
beforeEach(async () => {
  [owner, account2, account3, account4] = await ethers.getSigners();
  owner = owner.address;

  const LHNFTProfile = await ethers.getContractFactory("LHNFTProfile");
  nftProfile = await upgrades.deployProxy(LHNFTProfile, { kind: "uups" });
});

describe("NFTProfile Contract", () => {
  it("Should set the right owner", async () => {
    expect(await nftProfile.owner()).to.equal(owner);
  });
  it("Should mint", async () => {
    let tx = await nftProfile.safeMint(owner, "https://sdsd.vom");
    tx = await tx.wait();
    expect(tx.events[0].args["tokenId"]).to.equal(1);
  });
  it("Should not mint double", async () => {
    let tx = await nftProfile.safeMint(owner, "https://sdsd.vom");
    tx = await tx.wait();
    try {
      tx = await nftProfile.safeMint(owner, "https://sdsd.vom");
      tx = await tx.wait();
    } catch (e) {
      expect(e.message).to.equal(
        "VM Exception while processing transaction: reverted with reason string 'Account already has a profile'",
      );
    }
  });
  it("Should be the owner of token", async () => {
    let tx = await nftProfile.safeMint(owner, "https://sdsd.vom");
    tx = await tx.wait();
    expect(tx.events[0].args["tokenId"]).to.equal(1);
    expect(await nftProfile.ownerOf(tx.events[0].args["tokenId"])).to.equal(owner);
    expect(await nftProfile.getTokenID(owner)).to.equal(tx.events[0].args["tokenId"]);
  });

  it("account with no token", async () => {
    expect(await nftProfile.getTokenID(account4.address)).to.equal(0);
  });
  it("Should be the owner of token", async () => {
    let tx = await nftProfile.safeMint(owner, "https://sdsd.vom");
    tx = await tx.wait();
    tx = await nftProfile.safeMint(account4.address, "https://sdsd.vom");
    tx = await tx.wait();

    try{
    tx = await nftProfile.transferFrom(owner, account4.address, 1);
    console.log(tx);
  }catch(e){
    expect(e.message).to.equal(
      "VM Exception while processing transaction: reverted with reason string 'Account already has a token'",
    );
  }
  });
});
