/* eslint no-use-before-define: "warn" */
const { ethers } = require("hardhat");
const R = require("ramda");

const main = async () => {
  console.log("\n\n 📡 Deploying...\n");
  console.log("hello from deploy script");

  const usdc_rinkeby = "0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b";
  const Erc20 = await ethers.getContractAt("ERC20", usdc_rinkeby);
  const bondable_rinkeby = "0xBad3C77Aa9AAdce817F6395da84071B36cb99fE0";

  // approve
  const s = await ethers.getSigner();
  const amount = ethers.utils.parseEther("1");
  const tx = await Erc20.approve(bondable_rinkeby, amount);
};

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
