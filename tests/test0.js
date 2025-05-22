const convert = (amount, decimals) => ethers.utils.parseUnits(amount, decimals);
const divDec = (amount, decimals = 18) => amount / 10 ** decimals;
const { expect } = require("chai");
const { ethers, network } = require("hardhat");
const { execPath } = require("process");

const AddressZero = "0x0000000000000000000000000000000000000000";
const RandomNumber =
  "0x0000000000000000000000000000000000000000000000000000000000000001";
const pointZeroOne = convert("0.01", 18);
const ten = convert("10", 18);

let owner, treasury, developer, incentives, user0, user1, user2, user3;
let base, vaultFactory;
let crate;

describe("local: test0", function () {
  before("Initial set up", async function () {
    console.log("Begin Initialization");

    [owner, treasury, developer, incentives, user0, user1, user2, user3] =
      await ethers.getSigners();

    const baseArtifact = await ethers.getContractFactory("Base");
    base = await baseArtifact.deploy();
    console.log("- Base Initialized");

    const vaultFactoryArtifact = await ethers.getContractFactory(
      "BerachainRewardVaultFactory"
    );
    vaultFactory = await vaultFactoryArtifact.deploy();
    console.log("- Vault Factory Initialized");

    const crateArtifact = await ethers.getContractFactory("Crate");
    crate = await crateArtifact.deploy(
      base.address,
      treasury.address,
      developer.address,
      incentives.address,
      vaultFactory.address,
      AddressZero
    );
    console.log("- Crate Initialized");

    await crate.initialize();

    console.log("Initialization Complete");
    console.log();
  });

  it("First test", async function () {
    console.log("******************************************************");
  });

  it("User0 opens a crate", async function () {
    console.log("******************************************************");

    console.log("Before Play:");
    console.log(
      "Crate BERA Balance:",
      divDec(await ethers.provider.getBalance(crate.address))
    );
    console.log(
      "Crate WBERA Balance:",
      divDec(await base.balanceOf(crate.address))
    );
    console.log(
      "User WBERA Balance:",
      divDec(await base.balanceOf(user0.address))
    );

    await crate
      .connect(user0)
      .open(user0.address, RandomNumber, { value: pointZeroOne });

    console.log("\nAfter Play:");
    console.log(
      "Crate BERA Balance:",
      divDec(await ethers.provider.getBalance(crate.address))
    );
    console.log(
      "Crate WBERA Balance:",
      divDec(await base.balanceOf(crate.address))
    );
    console.log(
      "User WBERA Balance:",
      divDec(await base.balanceOf(user0.address))
    );
  });

  it("Owner mints WBERA to crate", async function () {
    console.log("******************************************************");

    console.log("Before Play:");
    console.log(
      "Crate BERA Balance:",
      divDec(await ethers.provider.getBalance(crate.address))
    );
    console.log(
      "Crate WBERA Balance:",
      divDec(await base.balanceOf(crate.address))
    );

    await base.connect(owner).deposit({ value: ten });
    await base.connect(owner).transfer(crate.address, ten);

    console.log("\nAfter Play:");
    console.log(
      "Crate BERA Balance:",
      divDec(await ethers.provider.getBalance(crate.address))
    );
    console.log(
      "Crate WBERA Balance:",
      divDec(await base.balanceOf(crate.address))
    );
  });

  it("User0 opens a crate", async function () {
    console.log("******************************************************");

    for (let i = 0; i < 10; i++) {
      console.log("Before Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );

      await crate
        .connect(user0)
        .open(user0.address, RandomNumber, { value: pointZeroOne });

      console.log("\nAfter Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );
    }
  });

  it("User1 opens a crate", async function () {
    console.log("******************************************************");

    for (let i = 0; i < 10; i++) {
      console.log("Before Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );

      await crate
        .connect(user1)
        .open(user1.address, RandomNumber, { value: pointZeroOne });

      console.log("\nAfter Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );
    }
  });

  it("User2 opens a crate", async function () {
    console.log("******************************************************");

    for (let i = 0; i < 10; i++) {
      console.log("Before Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );

      await crate
        .connect(user2)
        .open(user2.address, RandomNumber, { value: pointZeroOne });

      console.log("\nAfter Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );
    }
  });

  it("Owner sets indexes", async function () {
    console.log("******************************************************");
    await crate.connect(owner).setIndexRange(50, 69, 10);
    await crate.connect(owner).setIndexRange(70, 79, 25);
    await crate.connect(owner).setIndexRange(80, 89, 50);
    await crate
      .connect(owner)
      .setIndexes(
        [90, 91, 92, 93, 94, 95, 96, 97, 98],
        [100, 100, 100, 100, 100, 200, 200, 200, 500]
      );
    await crate.connect(owner).setIndex(99, 1000);
  });

  it("User0 opens a crate", async function () {
    console.log("******************************************************");

    for (let i = 0; i < 10; i++) {
      console.log("Before Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );

      await crate
        .connect(user0)
        .open(user0.address, RandomNumber, { value: pointZeroOne });

      console.log("\nAfter Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );
    }
  });

  it("Owner mints WBERA to crate", async function () {
    console.log("******************************************************");

    console.log("Before Play:");
    console.log(
      "Crate BERA Balance:",
      divDec(await ethers.provider.getBalance(crate.address))
    );
    console.log(
      "Crate WBERA Balance:",
      divDec(await base.balanceOf(crate.address))
    );

    await base.connect(owner).deposit({ value: ten });
    await base.connect(owner).transfer(crate.address, ten);

    console.log("\nAfter Play:");
    console.log(
      "Crate BERA Balance:",
      divDec(await ethers.provider.getBalance(crate.address))
    );
    console.log(
      "Crate WBERA Balance:",
      divDec(await base.balanceOf(crate.address))
    );
  });

  it("User1 opens a crate", async function () {
    console.log("******************************************************");

    for (let i = 0; i < 10; i++) {
      console.log("Before Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );

      await crate
        .connect(user1)
        .open(user1.address, RandomNumber, { value: pointZeroOne });

      console.log("\nAfter Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );
    }
  });

  it("User2 opens a crate", async function () {
    console.log("******************************************************");

    for (let i = 0; i < 10; i++) {
      console.log("Before Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );

      await crate
        .connect(user2)
        .open(user2.address, RandomNumber, { value: pointZeroOne });

      console.log("\nAfter Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );
    }
  });

  it("Owner sets indexes", async function () {
    console.log("******************************************************");
    await crate.connect(owner).setIndexRange(50, 69, 500);
    await crate.connect(owner).setIndexRange(70, 79, 500);
    await crate.connect(owner).setIndexRange(80, 89, 500);
    await crate
      .connect(owner)
      .setIndexes(
        [90, 91, 92, 93, 94, 95, 96, 97, 98],
        [500, 500, 500, 500, 500, 500, 500, 500, 500]
      );
    await crate.connect(owner).setIndex(99, 5000);
  });

  it("User0 opens a crate", async function () {
    console.log("******************************************************");

    for (let i = 0; i < 10; i++) {
      console.log("Before Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );

      await crate
        .connect(user0)
        .open(user0.address, RandomNumber, { value: pointZeroOne });

      console.log("\nAfter Play:");
      console.log(
        "Crate BERA Balance:",
        divDec(await ethers.provider.getBalance(crate.address))
      );
      console.log(
        "Crate WBERA Balance:",
        divDec(await base.balanceOf(crate.address))
      );
      console.log(
        "User WBERA Balance:",
        divDec(await base.balanceOf(user0.address))
      );
    }
  });
});
