/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("dotenv").config();
require("solidity-coverage")
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-web3");

const MAINNET_RPC_URL =
  process.env.MAINNET_RPC_URL || process.env.ALCHEMY_MAINNET_RPC_URL || "";
const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL || "";
const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL || "";
const MNEMONIC = process.env.MNEMONIC || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// optional
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

task("balance", "Prints an account's balance")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs) => {
    const account = web3.utils.toChecksumAddress(taskArgs.account);
    const balance = await web3.eth.getBalance(account);

    console.log(web3.utils.fromWei(balance, "ether"), "ETH");
  });
 
module.exports = {
  // defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      // // If you want to do some forking, uncomment this
      // forking: {
      //   url: MAINNET_RPC_URL
      // }
    },
    localhost: {},
    kovan: {
      url: KOVAN_RPC_URL,
      accounts: [PRIVATE_KEY],
      // accounts: {
      //     mnemonic: MNEMONIC,
      // },
      saveDeployments: true,
    },
    rinkeby: {
      url: RINKEBY_RPC_URL,
      accounts: [PRIVATE_KEY],
      // accounts: {
      //     mnemonic: MNEMONIC,
      // },
      saveDeployments: true,
    },
    ganache: {
      url: "http://localhost:8545",
      accounts: [PRIVATE_KEY],
      // accounts: {
      //     mnemonic: MNEMONIC,
      // }
    },
    fantomTest: {
      url: "https://rpc.ankr.com/fantom_testnet/",
      accounts: [PRIVATE_KEY],
      // accounts: {
      //     mnemonic: MNEMONIC,
      // }
    },
    mainnet: {
      url: MAINNET_RPC_URL,
      accounts: [PRIVATE_KEY],
      // accounts: {
      //     mnemonic: MNEMONIC,
      // },
      saveDeployments: true,
    },
    polygon: {
      url: "https://rpc-mainnet.maticvigil.com/",
      accounts: [PRIVATE_KEY],
      // accounts: {
      //     mnemonic: MNEMONIC,
      // },
      saveDeployments: true,
    },
    matictestnet: {
      url: "https://rpc-mumbai.maticvigil.com/",
      accounts: [PRIVATE_KEY],
      saveDeployments: true,
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
      1: 0, // similarly on mainnet it will take the first account as deployer. Note though that depending on how hardhat network are configured, the account 0 on one network can be different than on another
    },
    feeCollector: {
      default: 1,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.4",
      },
      {
        version: "0.7.0",
      },
      {
        version: "0.6.6",
      },
      {
        version: "0.4.24",
      },
    ],
    mocha: {
      timeout: 100000,
    },
  },
};
