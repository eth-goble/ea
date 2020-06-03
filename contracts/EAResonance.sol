// SPDX-License-Identifier: GPL-2.0-only
/**
 * Resonance
 * v1.0
 */
pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

import "./Pausable.sol";
import "./EAToken.sol";
import "./Terminators.sol";

contract EAResonance is Pausable, Terminators {
    uint256 private _amount;
    uint256 private _sold;
    uint256 private _leaderAmount;
    uint256 private _terminatorAmount;
    uint private _index;
    EAToken private _eat;

    /// award
    uint[15] private LEADER_AWARD =[
        35,
        20,
        15,
        10,
        5,
        4,
        3,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1
    ];

    mapping(address => uint256) _leadersAward;
    address[] private _leaders;
    uint NOT_INIT = 17;
    mapping (address => uint256) private _resonance; // resonance value

    // 153 items
    uint256[] private R_TABLE = [
        10 ether,21 ether,33 ether,46 ether,60 ether,75 ether,91 ether,108 ether,126 ether,145 ether,
        165 ether,186 ether,208 ether,231 ether,255 ether,280 ether,306 ether,333 ether,361 ether,390 ether,
        420 ether,451 ether,483 ether,516 ether,550 ether,585 ether,621 ether,658 ether,696 ether,735 ether,
        775 ether,816 ether,858 ether,901 ether,945 ether,990 ether,1036 ether,1083 ether,1131 ether,1180 ether,
        1230 ether,1281 ether,1333 ether,1386 ether,1440 ether,1495 ether,1551 ether,1608 ether,1666 ether,
        1725 ether,1785 ether,1846 ether,1908 ether,1971 ether,2035 ether,2100 ether,2166 ether,2233 ether,
        2301 ether,2370 ether,2440 ether,2511 ether,2583 ether,2656 ether,2730 ether,2805 ether,2881 ether,
        2958 ether,3036 ether,3115 ether,3195 ether,3276 ether,3358 ether,3441 ether,3525 ether,3610 ether,
        3696 ether,3783 ether,3871 ether,3960 ether,4050 ether,4115 ether,4325 ether,4539 ether,4757 ether,
        4980 ether,5207 ether,5439 ether,5676 ether,5918 ether,6164 ether,6415 ether,6929 ether,7452 ether,
        7987 ether,8532 ether,9088 ether,9656 ether,10235 ether,10827 ether,11430 ether,12045 ether,12988 ether,
        13949 ether,14930 ether,15931 ether,16952 ether,17995 ether,19058 ether,20144 ether,21251 ether,22381 ether,
        24303 ether,26264 ether,28265 ether,30307 ether,32390 ether,34516 ether,36686 ether,38900 ether,41159 ether,
        43464 ether,45816 ether,48216 ether,50665 ether,53164 ether,55714 ether,58316 ether,60971 ether,63680 ether,
        66445 ether,69266 ether,72145 ether,75082 ether,78079 ether,81138 ether,84259 ether,87443 ether,90693 ether,
        94009 ether,97393 ether,100845 ether,104368 ether,107963 ether,111632 ether,115375 ether,119195 ether,
        123092 ether,127069 ether,131128 ether,135269 ether,139495 ether ];

    uint256[] private O_TABLE = [
        25000000000,24500000000,24010000000,23529800000,23059204000,22598019920,22146059522,21703138331,21269075565,
        20843694053,20426820172,20018283769,19617918093,19225559732,18841048537,18464227566,18094943015,17733044155,
        17378383271,17030815606,16690199294,16356395308,16029267402,15708682054,15394508413,15086618244,14784885880,
        14489188162,14199404399,13915416311,13637107985,13364365825,13097078508,12835136938,12578434199,12326865515,
        12080328205,11838721641,11601947208,11369908264,11142510099,10919659897,10701266699,10487241365,10277496538,
        10071946607,9870507675,9673097521,9479635571,9290042859,9104242002,8922157162,8743714019,8568839739,8397462944,
        8229513685,8064923411,7903624943,7745552444,7590641395,7438828567,7290051996,7144250956,7001365937,6861338618,
        6724111846,6589629609,6457837017,6328680276,6202106671,6078064537,5956503247,5837373182,5720625718,5606213204,
        5494088940,5384207161,5276523018,5170992557,5067572706,4966221252,4866896827,4769558890,4674167713,4580684358,
        4489070671,4399289258,4311303473,4225077403,4140575855,4057764338,3976609051,3897076870,3819135333,3742752626,
        3667897574,3594539622,3522648830,3452195853,3383151936,3315488897,3249179119,3184195537,3120511626,3058101394,
        2996939366,2937000579,2878260567,2820695356,2764281449,2708995820,2654815903,2601719585,2549685193,2498691490,
        2448717660,2399743307,2351748440,2304713472,2258619202,2213446818,2169177882,2125794324,2083278438,2041612869,
        2000780612,1960764999,1921549699,1883118705,1845456331,1808547205,1772376261,1736928735,1702190161,1668146357,
        1634783430,1602087762,1570046006,1538645086,1507872185,1477714741,1448160446,1419197237,1390813292,1362997027,
        1335737086,1309022344,1282841897,1257185059,1232041358,1207400531,1183252520,1159587470,1136395721 ];

    constructor(EAToken _t) Terminators(17280) public {
        _eat = _t;
        _index = 0;
    }

    receive() external whenNotPaused payable {
        _do(msg.sender, msg.value);
    }
    
    function _do(address payable _account, uint256 _value) private {
        _earn(_account, _value);
        _updateLeaderBoardV2(_account); // update leader board
        _updateTerminatorsBoard(_account, _value); // update terminator board
    }

    /// calculate resonance value, returns EAToken amount and remain ether
    function _cal(uint256 _value) private returns(uint256, uint256) {
        if (_amount.add(_value) < R_TABLE[_index]) {
            uint256 retValue = _value.mul(O_TABLE[_index]).div(1 ether);
            _amount = _amount.add(_value);
            return (retValue, 0);
        } else {
            uint256 value = R_TABLE[_index].sub(_amount);
            uint256 retValue = value.mul(O_TABLE[_index]).div(1 ether);
            uint256 remain = _value.sub(value);
            _amount = _amount.add(value);
            _index++;
            return (retValue, remain);
        }
    }

    /// earn
    function _earn(address payable _account, uint256 _value) private {
        uint256 getValue = 0;
        uint256 callValue = _value;
        while(true) {
            (uint256 retValue, uint256 remain) = _cal(callValue);
            callValue = remain;
            getValue = getValue.add(retValue);
            if (remain == 0) {
                break;
            }
        }
        _leaderAmount = _leaderAmount.add(_value.div(10));
        _terminatorAmount = _terminatorAmount.add(_value.mul(3).div(100));
        _eat.transfer(_account , getValue);
        _resonance[_account] = _resonance[_account].add(_value);
        _sold = _sold.add(getValue);
    }

    /// leaderBoardV2
    function _updateLeaderBoardV2(address _account) private {
        bool find = false;
        for (uint i = 0; i < _leaders.length; i++) {
            if (_leaders[i] == _account) {
                find = true;
                break;
            }
        } 
        if (!find) {
            if (_leaders.length < NOT_INIT) {
                _leaders.push(_account);
            } else {
                _leaders[NOT_INIT - 1] = _account;
            }
        }
        address temp;
        for (uint i = 1; i < _leaders.length; i++) {
            temp = _leaders[i];
            uint j  = i;
            for (; j > 0; j--) {
                if (_resonance[_leaders[j-1]] < _resonance[temp]) {
                    _leaders[j] = _leaders[j-1];
                } else {
                    break;
                }
            }
            _leaders[j] = temp;
        }
    }

    function setRTable(uint256[] calldata data) external onlyOwner {
        R_TABLE = data;
    }

    function setOTable(uint256[] calldata data) external onlyOwner {
        O_TABLE = data;
    }

    function debugClearLeaders() external onlyOwner {
        delete _leaders;
    }

    function pushRODate(uint256 _r, uint256 _o) external onlyOwner {
        R_TABLE.push(_r);
        O_TABLE.push(_o);
    }

    function leadersAward(address _account) external view returns (uint256) {
        return _leadersAward[_account];
    }

    function getRTable() external view returns(uint256[] memory) {
        return R_TABLE;
    }

    function getLeaderAward() external view returns(uint[15] memory) {
        return LEADER_AWARD;
    }

    function getOTable() external view returns(uint256[] memory) {
        return O_TABLE;
    }

    function leaders() external view returns(address[] memory) {
        return _leaders;
    }
    
    /// resonance amount
    function resonance(address _account) external view returns(uint256) {
        return _resonance[_account];
    }

    function sold() external view returns(uint256) {
        return _sold;
    }

    function amount() external view returns(uint256) {
        return _amount;
    }

    function latestPrice() external view returns(uint256) {
        return O_TABLE[_index];
    }

    function index() external view returns(uint256) {
        return _index;
    }

    function leaderAmount() external view returns(uint256) {
        return _leaderAmount;
    }

    function terminatorAmount() external view returns(uint256) {
        return _terminatorAmount;
    }
}
