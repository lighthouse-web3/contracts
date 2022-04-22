const { ethers } = require("hardhat");

async function main(){
    const [deployer]= await ethers.getSigners();

    console.log(`Deploying contracts with the accounts: ${deployer.address}`);

    const balance = await deployer.getBalance();
    console.log(`Acccount Balance: ${balance.toString()}`);

    const Deposit = await ethers.getContractFactory('DepositManagerDai');
    const deposit = await Deposit.deploy("0x5A01Ea01Ba9A8DC2B066714A65E61a78838B1b9e");

    console.log(`Deposit deployed at : ${deposit.address}`);
}

main()
    .then(()=> process.exit(0))
    .catch(error=>{
        console.error(error);
        process.exit(1);
    });