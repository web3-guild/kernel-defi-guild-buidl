// SPDX-License-Identifier: CC0
pragma solidity ^0.8.9;

import "./utils/types.sol";
import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/tokens/ERC20/IERC20.sol";
import "./interfaces/IBurnableToken.sol";
/// @title Bond contract 
/// @author Dhruv 
/// @notice this contract is based on ERC3475 standard which allows to issue and maange bonds.
/// @dev ref implementation : https://github.com/Debond-Protocol/EIP-3475

contract KernelBond is IERC3475  {
    // for bonds that allow for changes of the bond classes and other details.
    Roles.role private manager;
    // mapping of HOlderAddress => operatorAddress => amountOfBondsAllowed.
    mapping(address => mapping(address => bool)) _operatorApprovals;
    // defines the user deposits after issuing of bonds and also allowing for redemption.
    mapping(address => uint) userDeposits;
   
    mapping(uint256 => Class) internal _classes;
    mapping(uint256 => IERC3475.Metadata) _classMetadata;

    address zcToken;
   
   modifier onlyManager(address funcCaller) {
    require(manager.has(funcCaller), "Bond:Only-owner-allowed-call");
    _;
   }

    modifier onlyBondOwner(address bondOwner) {
    require(msg.sender == bondOwner, "Bond:Only-bond-owner-can-transfer");
    _;
    }

   
    constructor(address _zcToken) {
        manager.add(msg.sender);
        // here we will define some initial type of bond classes that are solely allowed for bond issuers to buy.
        // apart from that also we will define classMetadata which will be used for frontend to interpret the onchain data type and other associated information.
        // each data has following info
        /**
         * title being the string description for the bonds.
         * type  is the data type of the details stored (uint , string , bool etc.)
         * description is the type of the metadata stored.
         * then based on the type, you use the information.
         */
        // for start we store name , underlying, maturityTime and maxDebt in class.
        // here its name, symbol, 
        _classMetadata[0].title = "name";
        _classMetadata[0]._type = "string";
        _classMetadata[0].description = "name of the class";


        _classMetadata[1].title = "underlyingAsset";
        _classMetadata[1]._type = "string";
        _classMetadata[1].description = "underlying asset address";

        _classMetadata[2].title = "maturityTimePeriod";
        _classMetadata[2]._type = "uint";
        _classMetadata[2].description = "time period for bond maturity";

        _classMetadata[3].title = "maxDebt";
        _classMetadata[3]._type = "uint";
        _classMetadata[3].description = "maximum issuance of debt tokens";


        // defining the nonce metadatas 



        // now storing the actual values of class (for the test demonstration purposes).
        // these can be also set by the addClass method from the bondIssuer.addClass() contract.
        _classes[0]._values[0].stringValue = "Kernel-6Month-USDC";
        _classes[0]._values[1].addressValue = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';// considering USDC token issuance
        _classes[0]._values[2].uintValue = 180 days; // timePeriod for the maturity.
        _classes[0]._values[3].uintValue = 1000000000; // max debt value.
        // creating another class for the test purposes (instantaneous bond issuance/redemption)
        _classes[1]._values[0].stringValue = "Kernel-instantaneous-USDC";
        _classes[1]._values[1].stringValue = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';// considering USDC token issuance
        _classes[1]._values[2].uintValue = 2; // for test having timePeriod as 2 second to redeem instantaneously.
        _classes[1]._values[3].uintValue = 10000000000; // max debt value.


        zcToken = _zcToken;


    }

    // getter functions : 





    // state changing functions. 

    /// @notice issues the bond to the user with the derivative tokens (similar to mint in previous contract).
    /// @dev this function is callable only by the bondIssuer contract.
    /// @param _to is the destination address receiving the bonds after depositing the underlying asset. 
    /// @param _transactions is the tuple struct to pass the {classId, nonceId, amount of issued debt token }
    /// @return 

    function issue(address _to, Transaction[] calldata _transactions) external virtual  returns() {
    uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                _to != address(0),
                "ERC3475: can't issue to the zero address"
            );
            _issue(_to, _transactions[i]);
        }
        emit Issue(msg.sender, _to, _transactions);

    }
    function transferFrom(
        address _from,
        address _to,
        Transaction[] calldata _transactions
    ) public virtual onlyBondOwner(_from) override {
    
    require(_from != address(0) && _to != address(0), "Bond:illegal-addresses");

    require(
        msg.sender == _from ||
        isApprovedFor(_from, msg.sender),
        "Bond:caller-not-owner-or-approved"
        );
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            _transferFrom(_from, _to, _transactions[i]);
        }
        emit Transfer(msg.sender, _from, _to, _transactions);

    }

    function transferAllowanceFrom(address _from,
        address _to,
        Transaction[] calldata _transactions
        ) public virtual override {
        require(_from != address(0) && _to != address(0), "Bond:illegal-addresses");
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            require(
                _transactions[i].amount <= allowance(_from, msg.sender, _transactions[i].classId, _transactions[i].nonceId),
                "Bond:caller-not-owner-or-approved"
            );
            _transferAllowanceFrom(msg.sender, _from, _to, _transactions[i]);
        }
        emit Transfer(msg.sender, _from, _to, _transactions);
        }


    /// defined as  repay in the orignal bond contract, allows user to repay the debt.
    function burn(address _from, Transaction[] calldata _transactions)
    external
    virtual
    override
    {
        require(
            _from != address(0),
            "Bond:address(0)-cant-burn"
        );
        require(
            msg.sender == _from ||
            isApprovedFor(_from, msg.sender),
            "Bond:caller-not-owner-or-approved"
        );
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            _burn(_from, _transactions[i]);
        }
        emit Burn(msg.sender, _from, _transactions);
    }

    function redeem(address _from, Transaction[] calldata _transactions)
    external
    virtual
    override
    {
        require(
            _from != address(0),
            "Bond:address(0) cant redeem the bonds"
        );
        uint256 len = _transactions.length;
        for (uint256 i = 0; i < len; i++) {
            (, uint256 progressRemaining) = getProgress(
                _transactions[i].classId,
                _transactions[i].nonceId
            );
            require(
                progressRemaining == 0,
                "ERC3475 Error: Not redeemable"
            );
            _redeem(_from, _transactions[i]);
        }
        emit Redeem(msg.sender, _from, _transactions);
    }

    /// @notice allows the bond holder to allow _spender address to delegate the bonds of identifier {classId,NonceId,amountApproved}
    /// @dev generally needs to check if the ownership of the msg.sender for all of the transaction structs as input by the _transaction structure.
    /// @param _spender is the third party address which will delegate the bonds.
    function approve(address _spender, Transaction[] calldata _transactions)
    external
    virtual
    override
    {   require()
        for (uint256 i = 0; i < _transactions.length; i++) {
            _classes[_transactions[i].classId]
            ._nonces[_transactions[i].nonceId]
            ._allowances[msg.sender][_spender] = _transactions[i].amount;
        }
    }

    function setApprovalFor(
        address operator,
        bool approved
    ) public virtual override {
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalFor(msg.sender, operator, approved);
    }


// readables 
    // defines the supply of all the debts (minted, repaid and claimed).
    function totalSupply(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256)
    {
        return (activeSupply(classId, nonceId) +
        burnedSupply(classId, nonceId) +
        redeemedSupply(classId, nonceId)
        );
    }

    // defines the current debt that is minted 
    function activeSupply(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256)
    {
        return _classes[classId]._nonces[nonceId]._mintedDebt;
    }

    // defines the supply that is repaid
    function burnedSupply(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256)
    {
        return _classes[classId]._nonces[nonceId]._repaidDebt;
    }

    // defines the supply that is claimed

    function redeemedSupply(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256)
    {
        return _classes[classId]._nonces[nonceId]._claimedDebt;
    }

    // fetches the supply of debt held by individual issuer account for  classId,nonceId .
    function balanceOf(
        address account,
        uint256 classId,
        uint256 nonceId
    ) public view override returns (uint256) {
        require(
            account != address(0),
            "Bond: address(0)-null-balance"
        );
        return _classes[classId]._nonces[nonceId]._balances[account];
    }
    // allows to read the class metadata (as defined in the constructor)
    // metadataId is the index of the information that will be read.
    function classMetadata(uint256 metadataId)
    external
    view
    override
    returns (Metadata memory) {
        return (_classMetadata[metadataId]);
    }


    function nonceMetadata(uint256 classId, uint256 metadataId)
    external
    view
    override
    returns (Metadata memory) {
        return (_classes[classId]._nonceMetadatas[metadataId]);
    }

    function classValues(uint256 classId, uint256 metadataId)
    external
    view
    override
    returns (Values memory) {
        return (_classes[classId]._values[metadataId]);
    }


    function nonceValues(uint256 classId, uint256 nonceId, uint256 metadataId)
    external
    view
    override
    returns (Values memory) {
        return (_classes[classId]._nonces[nonceId]._values[metadataId]);
    }



    /** determines the progress till the  redemption of the bonds is valid  (based on the type of bonds class).
     * @notice ProgressAchieved and `progressRemaining` is abstract.
      For e.g. we are giving time passed and time remaining.
     */
    function getProgress(uint256 classId, uint256 nonceId)
    public
    view
    override
    returns (uint256 progressAchieved, uint256 progressRemaining){
        uint256 issuanceDate = _classes[classId]._nonces[nonceId]._values[0].uintValue;
        uint256 maturityDate = issuanceDate + _classes[classId]._nonces[nonceId]._values[5].uintValue;

        // check whether the bond is being already initialized:
        progressAchieved = block.timestamp - issuanceDate;
        progressRemaining = block.timestamp < maturityDate
        ? maturityDate - block.timestamp
        : 0;
    }
    /**
    gets the allowance of the bonds identified by (classId,nonceId) held by _owner to be spend by spender.
     */
    function allowance(
        address _owner,
        address spender,
        uint256 classId,
        uint256 nonceId
    ) public view virtual override returns (uint256) {
        return _classes[classId]._nonces[nonceId]._allowances[_owner][spender];
    }

    /**
    checks the status of approval to transfer the ownership of bonds by _owner  to operator.
     */
    function isApprovedFor(
        address _owner,
        address operator
    ) public view virtual override returns (bool) {
        return _operatorApprovals[_owner][operator];
    }


// internal functions


    function _issue(
        address _to,
        IERC3475.Transaction calldata _transaction
    ) private {
        uint maturity = _classes[_transaction.classId]._values[2].uintValue;
        address underlying = _classes[_transaction.classId]._values[2].addressValue;
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        
        require(block.timestamp <= block.timestamp + maturity,'bond has already matured');       
        require((amount + nonce._mintedDebt) <= _market.maximumDebt,'maximum debt exceeded');

        // first giving approval for bond contract (in case transferred bonds are redeemed). 
        //this is unsafe ad should only be used in production  by the proper admin controls on the function.
        IERC20(underlying).approve(address(this),_transaction.amount);

        //transfer balance to the tokens from the owner to this contract.
        IERC20(underlying).transferFrom(_to, address(this), _transaction.amount);
        // for now assuming 1:1 issuance of the bonnds.

        IERC20(zcToken).mint(_to,_transaction.amount )
        
        // then managing the remaining bonds.
        userDeposits[msg.sender] += _transaction.amount;
        nonce._balances[_to] += _transaction.amount;
        nonce._mintedDebt += _transaction.amount;
    }


    function _transferFrom(
        address _from,
        address _to,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        require(
            nonce._balances[_from] >= _transaction.amount,
            "Bond:Insufficient balance"
        );

        //transfer balance also.
        nonce._balances[_from] -= _transaction.amount;
        nonce._balances[_to] += _transaction.amount;
    }   
    
    function _transferAllowanceFrom(
        address _operator,
        address _from,
        address _to,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        require(
            nonce._balances[_from] >= _transaction.amount,
            "Bond:Insufficient-Allowance"
        );
        // reducing the allowance and decreasing accordingly.
        nonce._allowances[_from][_operator] -= _transaction.amount;
        // transferring the deposit also 
        userDeposits[_from] -= _transaction.amount;
        userDeposits[_to] += _transaction.amount;

        IERC20(zcToken).transferFrom(_from,_to, _transaction.amount);

        //transfer balance
        nonce._balances[_from] -= _transaction.amount;
        nonce._balances[_to] += _transaction.amount;


    }

    function _burn(
        address _from,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        // verify whether _amount of bonds to be burned are sfficient available for the given nonce of the bonds
        require(
            nonce._balances[_from] >= _transaction.amount,
            "ERC3475: not enough bond to transfer"
        );

        IERC20(underlying).transfer(address(this), _from, _transaction.amount);
        IBurnableToken(ZcToken).burnFrom(_from,_transaction.amount);
        //transfer balance
        nonce._balances[_from] -= _transaction.amount;
        nonce._repaidDebt += _transaction.amount;
    
    
    }



    function _redeem(
        address _from,
        IERC3475.Transaction calldata _transaction
    ) private {
        Nonce storage nonce = _classes[_transaction.classId]._nonces[_transaction.nonceId];
        // verify whether _amount of bonds to be redeemed  are sufficient available  for the given nonce of the bonds

        require(
            nonce._balances[_from] >= _transaction.amount,
            "ERC3475: not sufficient bond to be redeemed"
        );

        //transfer balance
        nonce._balances[_from] -= _transaction.amount;
        nonce._activeSupply -= _transaction.amount;
        nonce._claimedDebt -= _transaction.amount;
    }










}