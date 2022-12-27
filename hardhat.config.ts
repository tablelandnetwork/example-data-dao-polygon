// require('dotenv').config();
// require("@nomiclabs/hardhat-ethers");
// require("@nomiclabs/hardhat-etherscan");
import { HardhatUserConfig, extendEnvironment, task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import "@openzeppelin/hardhat-upgrades";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";
import * as dotenv from "dotenv";

dotenv.config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  gasReporter: {
    enabled: process.env.REPORT_GAS ? true : false,
    currency: "USD",
  },
  networks: {
    hardhat: {
      mining: {
        auto: !(process.env.HARDHAT_DISABLE_AUTO_MINING === "true"),
        interval: [100, 3000],
      },
    },
    polygon_mumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${
        process.env.POLYGON_MUMBAI_API_KEY ?? ""
      }`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY,
  },
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  proxies: {
    localhost: "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707",
  },
};

declare module "hardhat/types/config" {
  // eslint-disable-next-line no-unused-vars
  interface HardhatUserConfig {
    proxies: {
      [key: string]: string;
    };
  }
}

declare module "hardhat/types/runtime" {
  // eslint-disable-next-line no-unused-vars
  interface HardhatRuntimeEnvironment {
    proxy: string;
  }
}

extendEnvironment((hre: HardhatRuntimeEnvironment) => {
  // Get proxy address for user-selected network
  const proxies = hre.userConfig.proxies as any;
  hre.proxy = proxies[hre.network.name];
});

export default config;
