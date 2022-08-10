/* eslint-disable */
import { Button, Card, Input } from "antd";
import { useContractExistsAtAddress, useContractLoader } from "eth-hooks";
import { typeFromAST } from "graphql";
import React, { useMemo, useState, useEffect } from "react";
import toast from 'react-hot-toast';

export default function Bondable({
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
}) {
  const [address, setAddress] = useState("");
  const [admin, setAdmin] = useState("");
  const [marketKeys, setMarketKeys] = useState([]);
  const [underlying, setUnderlying] = useState("");
  const [maturity, setMaturity] = useState("");
  const [price, setPrice] = useState("");
  const [decimals, setDecimals] = useState("");
  const [maximumDebt, setMaximumDebt] = useState("");
  const [symbol, setSymbol] = useState("");
  const [tokenName, setTokenName] = useState("");

  const contracts = useContractLoader(provider, contractConfig, chainId);
  console.log("contracts", contracts);
  let contract;
  if (!customContract) {
    contract = contracts ? contracts[name] : "";
  } else {
    contract = customContract;
  }

  const createMarket = () => {
    console.log('createMarket', underlying);
    toast.error("To be implemented");
  };

  async function asyncSetAdmin(contract) {
    let admin = await contract.admin();
    setAdmin(admin);
  }

  async function asyncSetMarketKeys(contract) {
    let marketKeys = await contract.getMarketKeys();
    console.log('marketKeys', marketKeys);
    setMarketKeys(marketKeys);
  }

  useEffect(() => {
    console.log("ent2", contracts);
    if (contracts[name] !== undefined) {
      console.log("entered useEffect", contracts[name]);
      let bondableContract = contracts[name];
      setAddress(bondableContract.address);

      // call the function
      asyncSetAdmin(bondableContract).catch(console.error);
      asyncSetMarketKeys(bondableContract).catch(console.error);
    }
  }, [contracts]);

  return (
    <>
      <div style={{ margin: "auto", width: "70vw" }}>
        <Card
          title={
            <div style={{ fontSize: 24 }}>
              {name}
              <div style={{ float: "right" }}>
              </div>
            </div>
          }
          size="large"
          style={{ marginTop: 25, width: "100%" }}
        ></Card>

        <p>address {address}</p>
        <p>admin {admin}</p>
        <p>market keys {marketKeys}</p>
      </div>
      <div className="createMarket">
        <h2>create market</h2>
        <Input addonBefore="underlying" style={{ width: 600 }} value={underlying} onChange={(e) => setUnderlying(e.target.value)} />
        <br />
        <Input addonBefore="maturity" style={{ width: 600 }} value={maturity} onChange={(e) => setMaturity(e.target.value)} />
        <br />
        <Input addonBefore="maximumDebt" style={{ width: 600 }} value={maximumDebt} onChange={(e) => setMaximumDebt(e.target.value)} />
        <br />
        <Input addonBefore="price" style={{ width: 600 }} value={price} onChange={(e) => setPrice(e.target.value)} />
        <br />
        <Input addonBefore="decimals" style={{ width: 600 }} value={decimals} onChange={(e) => setDecimals(e.target.value)} />
        <br />
        <Input addonBefore="tokenName" style={{ width: 600 }} value={tokenName} onChange={(e) => setTokenName(e.target.value)} />
        <br />
        <Input addonBefore="symbol" style={{ width: 600 }} value={symbol} onChange={(e) => setSymbol(e.target.value)} />
        <br />
        <Button type="primary" onClick={createMarket} disabled={(underlying === "")}>Create market</Button>
      </div>
      
      <div className="mint_token">
        <h2>mint token (ToDo) </h2>
      </div>
    </>
  );
}
