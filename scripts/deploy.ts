import { ethers, network, upgrades } from "hardhat";
import { writeFileSync } from "fs";
import * as dotenv from "dotenv";

async function main() {
  const TableHolders = await ethers.getContractFactory("TableHolders");
  const tableHolders = await upgrades.deployProxy(TableHolders, [], {
    kind: "uups",
  });
  await tableHolders.deployed();

  console.log("proxy deployed to:", tableHolders.address, "on", network.name);

  const impl = await upgrades.erc1967.getImplementationAddress(tableHolders.address);
  console.log("New implementation address:", impl);

  // console.log("running post deploy");
  // await tableHolders._initMetadata();

  writeFileSync(`./.${network.name}.env`, `CONTRACT=${tableHolders.address}`, "utf-8");
  dotenv.config({ path: `./.${network.name}.env` });
  console.log(process.env.CONTRACT, "added");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
