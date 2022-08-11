// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Bondable {

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
    }

    address public admin;
    
    mapping (address => mapping (uint256 => Market)) public markets;
    // We store the keys of the above mapping for easier retrieval by the frontend.
    MarketTuple[] marketKeys;
    
    event marketCreated(address indexed underlying, uint256 indexed maturity, address indexed bond, uint256 maximumDebt, string name);
    
    constructor () {
        admin = msg.sender;
    }

    function getMarketKeys() public view returns (MarketTuple[] memory) {
        return marketKeys;
    }

    /// @notice Can be called to create a new debt market for a given underlying token
    /// @param underlying the address of the underlying token deposit
    /// @param maturity the maturity of the market
    /// @param price the issuance price on the bonds (a decimal stored as a base 1e18 uint256, issuance accurate to 8 digits precision)
    /// @param maximumDebt the maximum amount of debt/bonds to allow to be minted
    function createMarket(address underlying, uint256 maturity, uint256 maximumDebt, uint256 price, string memory marketName, string memory tokenName, string memory symbol) external onlyAdmin(admin) returns (address) {
        
        address bondAddress = address(new ZcToken(underlying, maturity, tokenName, symbol));
        
        markets[underlying][maturity] = Market(maximumDebt, price, 0, 0, 0, bondAddress, marketName);
        
        emit marketCreated(underlying, maturity, bondAddress, maximumDebt, marketName);
        MarketTuple memory marketTuple = MarketTuple(underlying, maturity);
        marketKeys.push(marketTuple);
        return (bondAddress);
    }
    
    /// @notice Can be called to mint/purchase a new bond
    /// @param underlying the address of the underlying token deposit
    /// @param maturity the maturity of the market
    /// @param amount the amount of underlying tokens to lend
    function mint(address underlying, uint256 maturity, uint256 amount) external returns (uint256) {

        Market memory _market = markets[underlying][maturity];

        require(block.timestamp <= maturity,'bond has already matured');       
        require((amount + _market.mintedDebt) <= _market.maximumDebt,'maximum debt exceeded');

        SafeTransferLib.safeTransferFrom(ERC20(underlying), msg.sender, address(this), amount);

        uint256 mintAmount = amount * (1e26 / _market.price) / 1e8;
        ZcToken(_market.bond).mint(msg.sender, mintAmount);

        markets[underlying][maturity].mintedDebt += amount;

        return (mintAmount);
    }

    /// @notice Can be called after maturity to redeem debt owed
    /// @param underlying the underlying token being redeemed
    /// @param maturity the maturity of the market being redeemed
    /// @param amount the amount of underlying tokens to redeem and bond tokens to burn
    function redeem(address underlying, uint256 maturity, uint256 amount) external returns (uint256) {
        
        Market memory _market = markets[underlying][maturity];

        require(block.timestamp >= maturity,'bond maturity has not been reached');
        require((amount + _market.claimedDebt) <= _market.repaidDebt,'total market claim exceeds debt repaid');
        
        ZcToken(_market.bond).burn(msg.sender, amount);
        SafeTransferLib.safeTransfer(ERC20(underlying), msg.sender, amount);

        markets[underlying][maturity].claimedDebt += amount;
        
        return (amount);
    }

    /// @notice Can be called to pay towards a certain market's debt (generally called by the debtor)
    /// @param underlying the underlying token being redeemed
    /// @param maturity the maturity of the market being redeemed
    /// @param amount the amount of underlying token debt to pay
    function repay(address underlying, uint256 maturity, uint256 amount) external returns (uint256) {

        Market memory _market = markets[underlying][maturity];

        require((amount + _market.repaidDebt) <= _market.mintedDebt,'can not repay more debt than is minted');

        SafeTransferLib.safeTransfer(ERC20(underlying), msg.sender, amount);

        markets[underlying][maturity].repaidDebt += amount;

        return (amount);
    }

    /// @notice Allows the admin to set a new admin
    /// @param newAdmin Address of the new admin
    function transferAdmin(address newAdmin) external onlyAdmin(admin) returns (address) {
        admin = newAdmin;

        return (admin);
    }

    modifier onlyAdmin(address a) {
        require(msg.sender == admin, 'sender must be admin');
        _;
  }   
}

contract Token is ERC20 {
    constructor(string memory _name, string memory _symbol) 
    ERC20( _name, _symbol) {
        _mint(msg.sender, 100000000000000000000000);
    }
}


contract ZcToken is ERC20 {
    /// @dev unix timestamp when the ERC5095 token can be redeemed
    uint256 public immutable maturity;
    /// @dev address of the ERC20 token that is returned on ERC5095 redemption
    address public immutable underlying;
    /// @dev address of minter/burner
    address public immutable admin;

    error Authorized(address owner);

    constructor(address _underlying, uint256 _maturity, string memory _name, string memory _symbol) 
    ERC20( _name, _symbol) {
        underlying = _underlying;
        maturity = _maturity;
        admin = msg.sender;
    }
    /// @param f Address to burn from
    /// @param a Amount to burn
    function burn(address f, uint256 a) external onlyAdmin(admin) returns (bool) {
        _burn(f, a);
        return true;
    }

    /// @param t Address recieving the minted amount
    /// @param a The amount to mint
    function mint(address t, uint256 a) external onlyAdmin(admin) returns (bool) {
        _mint(t, a);
        return true;
    }

    modifier onlyAdmin(address a) {
        if (msg.sender != a) { revert Authorized(a); }
        _;
  }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}
