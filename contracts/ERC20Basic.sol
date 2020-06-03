pragma solidity ^0.6.4;

/**
 * @title ERC20Basic
 * @dev EA
 */
interface ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address _who) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
