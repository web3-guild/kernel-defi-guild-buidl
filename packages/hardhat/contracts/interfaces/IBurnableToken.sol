// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IBurnableToken {

function burnFrom(address _from, uint256 _amount) external; 

}