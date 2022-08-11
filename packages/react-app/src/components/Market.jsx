/* eslint-disable */
import { Button, Card, Input, Col, Row } from "antd";
import { useContractExistsAtAddress, useContractLoader } from "eth-hooks";
import { typeFromAST } from "graphql";
import React, { useMemo, useState, useEffect } from "react";
import { useParams } from "react-router-dom";
const { ethers } = require("ethers");

export default function Market({
  customContract,
  account,
  gasPrice,
  signer,
  provider,
  name,
  show,
  blockExplorer,
  chainId,
  contractConfig,
  location
}) {
  const [numTokens, setNumTokens] = useState("");

  const contracts = useContractLoader(signer, contractConfig, chainId);
  console.log("contracts", contracts);
  let contract;
  if (!customContract) {
    contract = contracts ? contracts[name] : "";
  } else {
    contract = customContract;
  }

  let { underlying, maturity } = useParams();

  const purchaseBond = async () => {
    console.log("purchaseBond", contract);
    
    // ToDo - Read decimals from underlying
    let tokensToMint = ethers.utils.parseUnits(numTokens, 18);
    await contract.mint(underlying, maturity, tokensToMint);
  };

  return (
    <>
      <h1>Market</h1>
      <p>Underlying {underlying}</p>
      <p>Maturity {maturity}</p>

      <Input
        addonBefore="quantity (tokens) * 1e18"
        style={{ width: 600 }}
        value={numTokens}
        onChange={e => setNumTokens(e.target.value)}
      />
      <br />
      <Button type="primary" onClick={purchaseBond} disabled={numTokens === ""}>
        Purchase bond
      </Button>
    </>
  );
}
