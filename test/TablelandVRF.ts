import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";

describe("TablelandVRF", function () {
  // You should probably write tests;
  let accounts: SignerWithAddress[];
  let registry: any;
  let tablelandVRF: any;

  beforeEach(async function () {
    accounts = await ethers.getSigners();

    // const RegistryFactory = await ethers.getContractFactory("TablelandTables");
    // registry = await RegistryFactory.deploy();
    // await registry.deployed();
    // await registry.connect(accounts[0]).initialize("http://localhost:8080/");

    const TablelandVRF = await ethers.getContractFactory("TablelandVRF");
    tablelandVRF = await upgrades.deployProxy(TablelandVRF, [
      "https://testnet.tableland.network/query?s=",
      "not.implemented.com"
    ], {
      kind: "uups",
    });

    await tablelandVRF.deployed();

    // await tablelandVRF.connect(accounts[0]).createMetadataTable(registry.address);
  });
});
