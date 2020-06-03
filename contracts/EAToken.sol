// SPDX-License-Identifier: GPL-2.0-only
/**
 * EAToken
 * v1.0
 */
pragma solidity ^0.6.4;

import "./ERC20Basic.sol";
import "./SafeMath256.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract EAToken is ERC20Basic, Ownable, Pausable {
    using SafeMath256 for uint256;

    // ERC20 params
    string private _name = "EATokenV1.0";
    string private _symbol = "EA";
    uint8 private _decimals = 6;
    uint256 private _totalSupply;
    mapping(address => uint256) internal balances;
    address[] private _ctl;

    event Mint(address indexed to, uint256 amount);

    /// move tokens
    function _move(address from, address to, uint256 value) private {
        require(value <= balances[from], "EAToken: [_move] balance not enough");
        require(to != address(0), "EAToken: [_move] to[address] is illegal");

        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
    }

    /// transfer token
    function transfer(address to, uint256 value) public whenNotPaused override returns (bool) {
        _move(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    /// erc20 interface
    function name() public view returns (string memory) {
        return _name;
    }

    /// erc20 interface
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// erc20 interface
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /// erc20 interface
    function balanceOf(address _owner) public override view returns (uint256) {
        return balances[_owner];
    }

    /// erc20 interface
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /// get gameCtl
    function gameCtl() public view returns (address[] memory) {
        return _ctl;
    }

    /// set gameCtl
    function setGameCtl(address[] calldata _gc) external onlyOwner {
        _ctl = _gc;
    }

    // check ctl
    function _isCtl(address _addr) private view returns(bool) {
        for(uint i = 0; i < _ctl.length; i++) {
            if (_ctl[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    /// pay forward
    function payF(address _account, uint256 _value) external {
        require(_isCtl(msg.sender), "EAToken: must use game ctl");
        _move(_account, msg.sender, _value);
    }

    /// mint
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        _totalSupply = _totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }
}
