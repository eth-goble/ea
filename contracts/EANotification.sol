pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract EANotification is Ownable {

  struct Message {
    uint time;
    string content;
  }

  Message[] private _messages;

  function insert(string calldata _m) external onlyOwner {
    _messages.push(Message(block.timestamp, _m));
  }

  function length() external view returns (uint) {
    return _messages.length;
  }

  function message(uint index) external view returns(Message memory) {
    return _messages[index];
  }

  function messages() external view returns(Message[] memory) {
    return _messages;
  }
}
