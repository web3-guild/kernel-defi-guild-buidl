import "../interfaces/IERC3475.sol"    
  /*   
    struct Market {
        uint256 maximumDebt;
        uint256 price;
        uint256 mintedDebt;
        uint256 repaidDebt;
        uint256 claimedDebt;
        address bond;
        string name;
    }
    
 struct MarketTuple {
        address underlying;
        uint256 maturity;
    } */

// structure to define  the debt market.
struct Class { // storing the properties at the class level (bond class name ,underlying asset , maturity time )
        mapping(uint256 => IERC3475.Values) _values;
        mapping(uint256 => IERC3475.Metadata) _nonceMetadatas;
        mapping(uint256 => Nonce) _nonces;
}
// structure for issuing the different conditions of bond
struct Nonce {
        // values of other parameters (bond issuing time , supply, owner and bond address).
        mapping(uint256 => IERC3475.Values) _values;
        // stores the values corresponding to the dates (issuance and maturity date).
        mapping(address => uint256) _balances;
        // allowance of the owners of this bond to the other address.
        mapping(address => mapping(address => uint256)) _allowances;

        address owner;

        // supplies of the bonds for each corresponding issuance.
        uint256 _claimedDebt;
        uint256 _repaidDebt;
        uint256 _mintedDebt;
}

