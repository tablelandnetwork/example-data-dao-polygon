import { ethers, network, upgrades } from "hardhat";
import { writeFileSync } from "fs";
import * as dotenv from "dotenv";

async function main() {

  dotenv.config({ path: `./.${network.name}.env` });

  const token = process.env.CONTRACT;
  // Get proxy address
  if (token === undefined || token === "") {
    throw Error(`missing token entry`);
  }


  const TableGov = await ethers.getContractFactory("TableGov");
  const tableGov = await upgrades.deployProxy(TableGov, [token], {
    kind: "uups",
  });
  await tableGov.deployed();

  console.log("proxy deployed to:", tableGov.address, "on", network.name);

  const impl = await upgrades.erc1967.getImplementationAddress(tableGov.address);
  console.log("New implementation address:", impl);

  // console.log("running post deploy");
  // await tableGov._initMetadata();

  writeFileSync(`./.${network.name}.gov.env`, `CONTRACT=${tableGov.address}`, "utf-8");
  dotenv.config({ path: `./.${network.name}.gov.env` });
  console.log(tableGov.address, "added");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
