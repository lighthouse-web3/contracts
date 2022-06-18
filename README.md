# contracts
smart contracts for Lighthouse

## TO SetUp
----

- create a `.env` file
    Required*
    ```
    PRIVATE_KEY="WALLET_PRIVATE_KEY"
    ``` 
    Order configurable keys include
    ```
    RINKEBY_RPC_URL=""
    MAINNET_RPC_URL=""
    ALCHEMY_MAINNET_RPC_URL=""
    KOVAN_RPC_URL=""
    POLYGON_RPC_URL=""
    ETHERSCAN_API_KEY=""
    ```

- To set up dependency
    Ensure you have node and npm installed
    Optional(but recommended): 
     - [NVM](https://github.com/nvm-sh/nvm)
     - [Yarn](https://classic.yarnpkg.com/lang/en/docs/install/)

    finally run:  </br> <b> `npm install` or `yarn install`</b>


## Code coverage
---

To see a measure in percent of the degree to which the smart contract source code is executed when a particular test suite is run, type
```
yarn coverage
```
or
```
npx hardhat coverage
```

# Test
Tests are located in the [test](./test/) directory, and are split between unit tests and staging/testnet tests. Unit tests should only be run on local environments, and staging tests should only run on live environments.

To run unit tests:

```bash
yarn test
```
or
```
yarn hardhat test
```
or 
```
npx hardhat test
```


## Performance optimizations
---

Since all tests are written in a way to be independent from each other, you can save time by running them in parallel. Make sure that `AUTO_FUND=false` inside `.env` file. There are some limitations with parallel testing, read more about them [here](https://hardhat.org/guides/parallel-tests.html)

To run tests in parallel:
```
yarn test --parallel
```
or
```
yarn hardhat test --parallel
```
or 
```
npx hardhat test --parallel
```
