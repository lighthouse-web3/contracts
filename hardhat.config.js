/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("dotenv").config();
require("solidity-coverage");
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-web3");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");

const MAINNET_RPC_URL = process.env.MAINNET_RPC_URL || process.env.ALCHEMY_MAINNET_RPC_URL || "";
const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL || "";
const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL || "";
const POLYGON_RPC_URL = process.env.POLYGON_RPC_URL || "";
const MNEMONIC = process.env.MNEMONIC || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";
const REPORT_GAS = process.env.REPORT_GAS || false;

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
  .setAction(async taskArgs => {
    const account = web3.utils.toChecksumAddress(taskArgs.account);
    const balance = await web3.eth.getBalance(account);

    console.log(web3.utils.fromWei(balance, "ether"), "ETH");
  });

module.exports = {
  // defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000,
    },
    localhost: {
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000,
    },
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
      chainId: 4,
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
      name: "fantomTest",
      url: "https://rpc.ankr.com/fantom_testnet/",
      accounts: [PRIVATE_KEY],
      chainId: 4002,
      // accounts: {
      //     mnemonic: MNEMONIC,
      // }
    },
    fuji: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [PRIVATE_KEY],
      chainId: 43113,
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
      url: POLYGON_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 80001,
      saveDeployments: true,
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERSCAN_API_KEY,
  },
  gasReporter: {
    enabled: REPORT_GAS,
    currency: "USD",
    outputFile: "gas-report.txt",
    noColors: true,
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
        version: "0.6.12",
        settings: {},
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
