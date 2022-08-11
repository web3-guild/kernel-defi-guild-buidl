/* eslint-disable */
import { Button, Card, Input, Col, Row } from "antd";
import { useContractExistsAtAddress, useContractLoader } from "eth-hooks";
import { typeFromAST } from "graphql";
import React, { useMemo, useState, useEffect } from "react";
import { useHistory } from "react-router-dom";

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
  const history = useHistory();
  const [address, setAddress] = useState("");
  const [admin, setAdmin] = useState("");
  const [marketKeys, setMarketKeys] = useState([]);

  // input fields
  const [underlying, setUnderlying] = useState("");
  const [maturity, setMaturity] = useState("1672547971");
  const [maximumDebt, setMaximumDebt] = useState("100000000000000000000000");
  const [price, setPrice] = useState("95000000000000000000");
  const [marketName, setMarketName] = useState("0xKernel-5.25%-1672547971");
  const [tokenName, setTokenName] = useState("0xKernel-Dec-22-Debt");
  const [symbol, setSymbol] = useState("KERN-DEC");

  const contracts = useContractLoader(signer, contractConfig, chainId);

  //const contractConfig = { deployedContracts: deployedContracts || {}, externalContracts: externalContracts || {} };
  // Load in your local 📝 contract and read a value from it:
  //const readContracts = useContractLoader(localProvider, contractConfig);
  // If you want to make 🔐 write transactions to your contracts, use the userSigner:
  //const writeContracts = useContractLoader(userSigner, contractConfig, localChainId);

  console.log("contracts", contracts);
  let contract;
  if (!customContract) {
    contract = contracts ? contracts[name] : "";
  } else {
    contract = customContract;
  }

  const createMarket = async () => {
    console.log("createMarket", signer);
    //console.log('config', config);
    console.log('provider', provider);
    
    //let bondableContract = new ethers.ContractAt(ROUTER_ADDRESS, IUniswapV2Router02ABI, signer);
    await contract.createMarket(underlying, maturity, maximumDebt, price, marketName, tokenName, symbol);
    console.log("market created");
    await asyncSetMarketKeys();
  };

  async function asyncSetAdmin(contract) {
    let admin = await contract.admin();
    setAdmin(admin);
  }

  async function asyncSetMarketKeys(contract) {
    let marketKeys = await contract.getMarketKeys();
    console.log("marketKeys", marketKeys);
    setMarketKeys(marketKeys);
  }

  const handleClickMarket = (underlying, maturity) => {
    history.push(`/market/underlying/${underlying}/maturity/${maturity}`);
  };

  const getMarketKeysRepr = () => {
    let items = [];
    marketKeys.map((item, index) => {
      items.push(
        <div key={index}>
          <Card title="Market" style={{ width: 240 }}>
            <p> Underlying {item.underlying.toString()}</p>
            <p> Maturity {item.maturity.toString()}</p>
            <Button type="primary" onClick={() => handleClickMarket(item.underlying, item.maturity)}>
              Purchase bond
            </Button>
          </Card>
        </div>,
      );
    });
    return items;
  };

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
              <div style={{ float: "right" }}></div>
            </div>
          }
          size="large"
          style={{ marginTop: 25, width: "100%" }}
        ></Card>

        <p>address {address}</p>
        <p>admin {admin}</p>

        <p>market keys</p>
        {getMarketKeysRepr()}
      </div>
      <div className="createMarket">
        <h2>create market</h2>
        <Input
          addonBefore="underlying"
          style={{ width: 600 }}
          value={underlying}
          onChange={e => setUnderlying(e.target.value)}
        />
        <br />
        <Input
          addonBefore="maturity"
          style={{ width: 600 }}
          value={maturity}
          onChange={e => setMaturity(e.target.value)}
        />
        <br />
        <Input
          addonBefore="maximumDebt"
          style={{ width: 600 }}
          value={maximumDebt}
          onChange={e => setMaximumDebt(e.target.value)}
        />
        <br />
        <Input addonBefore="price" style={{ width: 600 }} value={price} onChange={e => setPrice(e.target.value)} />
        <br />
        <Input
          addonBefore="marketName"
          style={{ width: 600 }}
          value={marketName}
          onChange={e => setMarketName(e.target.value)}
        />
        <br />
        <Input
          addonBefore="tokenName"
          style={{ width: 600 }}
          value={tokenName}
          onChange={e => setTokenName(e.target.value)}
        />
        <br />
        <Input addonBefore="symbol" style={{ width: 600 }} value={symbol} onChange={e => setSymbol(e.target.value)} />
        <br />
        <Button type="primary" onClick={createMarket} disabled={underlying === ""}>
          Create market
        </Button>
      </div>
    </>
  );
}
