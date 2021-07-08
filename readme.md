### This folder contains Solidity contracts and deployment logic:
## 1. First Time Setup
- Run ```npm i``` in the contracts root folder (/EthDev/contracts)
- Create/copy a .env file in to the root folder

## 2. Contracts
- Contracts are written in Solidity (.sol) which compiles into Ethereum Virtual Machine code
- We use two main types of contracts:
  - Opportunity Contracts:
    - Read only contracts that are never executed on chain.  They are queried every block to get relevant data from the blockchain, such as prices on certain exchanges or optimal trade amounts 
  - Execution Contracts:
    - Make changes on chain, such as executing trades and transferring coins


## 3. Migrations
- The migrations files are used to define deployment procedures.  If contracts need to be linked together, or parameters need to be passed on creation, this is done in the migration files.  You can run a single migrations file or multiple (See Commands)


## 4. Truffle - Config
- The truffle-config.js file in each sub directory (ex. /DEX-Arbitrage) defines the configuration for compiling and deployment for each network.  You can set things such as the gas cost, maximum gas usage, node endpoints, deployment wallets, etc.

## 5 Truffle Tests
- You can specify tests to run in the /tests folder of each sub directory. 

## 6. Command Examples (In sub directory, such as /Dex-Arbitrage)
- Compile all contracts: 
  - ```truffle compile```
- To compile and deploy the contracts to the xdai network: (This runs only the second migrations file)
  - ```truffle migrate --network xdai --reset --f 2 --to 2```
- Run all migrations files for the main ethereum network: (You most likely only want to run one migration)
  - ```truffle migrate --network mainnet --reset```
- Run the FlashloanTest.js test script on the ropsten nework.  This uses gas, so probably not worth it on mainnet.
  - ```truffle test ./tests/FlashLoanTest.js --network ropsten --show-events```