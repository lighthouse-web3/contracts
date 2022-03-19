/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('@nomiclabs/hardhat-waffle');
const dotenv= require('dotenv');
dotenv.config();

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      forking:{
        url: "https://rpc-mainnet.maticvigil.com"
      }
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  solidity: {
    version: "0.7.3",
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};
