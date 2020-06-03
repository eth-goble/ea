pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath256.sol";

contract Terminators is Ownable {
    using SafeMath256 for uint256;
    struct TNode {
        address self;
        uint256 value;
        uint256 time;
    }
    uint _triggerBn = 17280;
    uint256 NUM_LIMIT = 15;
    TNode[] _terminators; // terminators
    uint256 _tHeadIndex = 0;
    uint256 _lastBlockNumber = 0;
    uint8 _triggered = 0;

    uint[] private _terminatorRecordIndex;
    mapping (uint => uint256[]) private _terminatorsSendRecords;
    mapping (address => uint256) private _terminatorsAward;

    constructor(uint _tbn) public {
        _triggerBn = _tbn;
    }

    /// update terminator board
    function _updateTerminatorsBoard(address _account, uint256 _value) internal {
        if (_triggered == 0) {
            if (_lastBlockNumber == 0) {
                _lastBlockNumber = block.number;
                return;
            }
            if (block.number - _lastBlockNumber >= _triggerBn) {
                _triggered = 1;
            } else {
                // update block number
                _lastBlockNumber = block.number;
            }
            if (_terminators.length < NUM_LIMIT) {
                _terminators.push(TNode(_account, _value, block.number));
            } else {
                _terminators[_tHeadIndex].self = _account;
                _terminators[_tHeadIndex].value = _value;
                _terminators[_tHeadIndex].time = block.number;
            }
            if (++_tHeadIndex >= NUM_LIMIT) {
                _tHeadIndex = 0;
            }
        }
    }

    /// sned to terminators
    function _sendToTerminators(uint256 _gasUse, uint256 _award, address payable _receive) internal {
        require(_triggered == 1, "EAGame: [sendToTerminators] send");
        TNode[] storage node = _terminators;
        uint len = node.length;
        uint256 award = 0;
        if (len != 0) {
            award = (_award.sub(_gasUse)).div(len);
            for (uint i = 0; i < len; i++) {
                address payable to = address(uint160(_terminators[i].self));
                to.transfer(award);
                _terminatorsAward[to] = _terminatorsAward[to].add(award);
            }
        }
        _terminatorRecordIndex.push(block.number);
        _terminatorsSendRecords[block.number].push(award);
        _receive.transfer(_gasUse);
    }

    function terminators() external view returns(TNode[] memory) {
        return _terminators;
    }

    function terminatorsAward(address _account) external view returns(uint256) {
        return _terminatorsAward[_account];
    }

    /// lastblocknumber
    function lastBlockNumber() external view returns(uint256) {
        return _lastBlockNumber;
    }

    function triggered() external view returns(uint8) {
        return _triggered;
    }
}
