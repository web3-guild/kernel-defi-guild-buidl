import logo from './logo.svg';
import './App.css';
import WalletConnect from "@walletconnect/web3-provider";

/////////// 

export const providerOptions = {
  walletconnect: {
    package: WalletConnect, 
    options: {
      infuraId: process.env.RINKEBY_INFURA_KEY 
    }
  }
 };
////////////

function App() {

  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Edit <code>src/App.js</code> and save to reload.
        </p>

      </header>

   
    </div>
  );
}

export default App;
