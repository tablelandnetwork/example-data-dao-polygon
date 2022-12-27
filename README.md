# WIP ERC-20 Data DAO built on Tableland and Polygon

This repo is a WIP. 

## Information

The main example token is `/contracts/TokenHolders.sol` and the `/contracts/TokenHoldersGov.sol`. Both of which were initially crafted in https://wizard.openzepplin.com and then supplemented in this repo. For development purposes, both are wrapped in proxy contracts. 

There is an additional example in `/contracts/GameIndex/` which shows how to limit the ability of the DAO to only modify data in a single table (created on contract initialization).

Finally, there is a WIP example using an NFT as the DAO membership token. 

## Governance

The token contracts are written using access control roles. You can wire the contracts together using https://defender.openzeppelin.com/ and after granting the governance contract the ability to execute the `TABLELAND_ROLE` functions, you can then vote using governance. 

You can use Tally to connect to your governance contract and host proposals & votes: https://www.tally.xyz/.

## Develop

You must have a `.env` file with the following information

```
PRIVATE_KEY={your wallet key with a balance of matic}
POLYGONSCAN_API_KEY={your polyscan api key for pushing the abi}
POLYGON_MUMBAI_API_KEY={your alchemy api key for mumbai}
REPORT_GAS=true
```

### Install

`npm install`

### Start Tableland locally

`npm run tableland`

### Deploy to local hardhat

`npm run local` or upgrade `npm run localup`

### Deploy to ERC-20 token to Mumbai

`npm run deploy`

### Deploy to Gov contract to Mumbai

`npm run deploy-gov`

## Change example you deploy

For now, you modify the contents of `scripts/deploy.ts` and `scripts/deploy-gov.ts` and `scripts/upgrade.ts` to point at the implementations in the `contracts/GameIndex` folder instead. Be sure to change their imports and the contract name they try to push. 

# Warning

This example is not maintained.
