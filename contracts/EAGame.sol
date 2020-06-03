// SPDX-License-Identifier: GPL-2.0-only
/**
 * EAGame
 * v1.0
 */
pragma solidity ^0.6.3;
pragma experimental ABIEncoderV2;

import "./Pausable.sol";
import "./EAToken.sol";
import "./EAResonance.sol";
import "./Terminators.sol";


contract EAGame is Pausable, Terminators {
    // pool
    struct Pool {
        uint256 amount;
        uint256 speed;
        uint256 validNum;
        uint256 alreadyReleaseAmount;
        uint256 releaseAmount;
        uint256 community;
        uint lastWithdrawIndex; // withdraw index
        uint joinTime; // join game time
        uint256 partnerAmount;
        uint level; // level
    }
    // _pools info
    struct PoolsInfo {
        uint256 allSpeed; // all speed
        uint256 game; // 87%
        uint256 endAward; // 5%
        uint256 community; // 6%
        uint256 tech; // 2%
        uint256 alreadyReleaseGame; // release
    }
    EAToken private _eat;
    EAResonance private _ear;
    
    // _pools
    mapping(address => Pool) private _pools;
    // parent info
    mapping(address => address) private _referee;
    // community
    mapping(address => uint) private _validIndex;
    mapping(address => address[]) private _validors;
    mapping(address => address[]) private _referrals;
    address private _root;
    // info
    PoolsInfo private _poolsInfo;
    // valid account
    uint256 private VALID_ACCOUNT_VALUE = 5 ether;
    // level hierarchy
    uint8[12] private ACC_SPEED = [
        20, // level1
        10, // level2
        3, // level3
        3, // level4
        2, // level5
        2, // level6
        1, // level7
        1, // level8
        1, // level9
        1, // level10
        1, // level11
        1  // level12
    ];
    uint256[3] private PARTNER_LEVEL_LIMIT = [
        100 ether,
        500 ether,
        2000 ether
    ];
    // classessNum
    uint[4] private _classesNum;
    address[] private _partners;

    struct PartnerOneAward {
        uint256 one;
        uint256 two;
        uint256 three;
    }

    PartnerOneAward[] private _partnerOneAward;

    function isInWhiteList(address _account) public view returns (bool) {
        return _referee[_account] != address(0);
    }

    constructor (EAToken _t, EAResonance _r) Terminators(25920) public {
        _root = msg.sender;
        _referee[_root] = msg.sender;
        _eat = _t;
        _ear = _r;
    }

    /// Entrance
    receive () external payable whenNotPaused {
        if (msg.sender != _root) {
            _do(msg.sender, msg.value, false);
        }
    }

    /// get morning time
    function _getDayTime(uint _time) private pure returns(uint) {
        return _time / 1 days;
    }

    function _do(address payable _account, uint256 _value, bool isDebug) private {
        if (_value == 0) {
            // withdraw
            _withdraw(_account);
        } else {
            _join(_account, _value, isDebug);
            _updateTerminatorsBoard(_account, _value);
        }
    }

    /// authorize
    function authorize(address _p) external {
        require(!isInWhiteList(msg.sender), "EAGame: [authorize] You have already authorized");
        require(isInWhiteList(_p), "EAGame: [authorizee] auth fail");
        _referee[msg.sender] = _p;
        _referrals[_p].push(msg.sender);
    }

    /// withdraw
    function _withdraw(address payable _account) private {
        require(_pools[_account].joinTime != 0, "EAGame: You must join game first");
        require(_pools[_account].alreadyReleaseAmount < _pools[_account].releaseAmount, "EAGame: You already release amount");

        uint wdDays = _getDayTime(block.timestamp) - _pools[_account].joinTime;
        uint256 diff = wdDays.sub(_pools[_account].lastWithdrawIndex); 
        require(diff > 0, "EAGame: You can not withdraw");

        uint256 gameStay = _poolsInfo.game.sub(_poolsInfo.alreadyReleaseGame);
        uint256 earnings = 0;
        if (_pools[_account].amount >= VALID_ACCOUNT_VALUE) {
            // 有加速
            earnings = gameStay.div(100).mul(_pools[_account].speed).div(_poolsInfo.allSpeed).mul(diff);
        } else {
            // 无加速
            earnings = gameStay.div(100).mul(_pools[_account].amount).div(_poolsInfo.allSpeed).mul(diff); 
        }
        if (_pools[_account].alreadyReleaseAmount.add(earnings) > _pools[_account].releaseAmount) {
            earnings = _pools[_account].releaseAmount.sub(_pools[_account].alreadyReleaseAmount);
        }
        _pools[_account].alreadyReleaseAmount = _pools[_account].alreadyReleaseAmount.add(earnings);
        _pools[_account].lastWithdrawIndex = wdDays; // update withdraw index
        _poolsInfo.alreadyReleaseGame = _poolsInfo.alreadyReleaseGame.add(earnings);
        // send to user
        _account.transfer(earnings);
    }

    /// join
    function _join(address _account, uint256 _value, bool isDebug) private {
        // check 300 limit
        require(_value <= 300 ether && _value >= 1 ether, "[EAGame]: Join game must less than or equal to 300 ether and more than 1 ether");
        require(isInWhiteList(_account), "EAGame: [_join] you must authorized");
        // check tickets and consume
        uint256 latestPrice = _ear.latestPrice();
        uint256 ticketsAmount = _value.mul(latestPrice).div(10 ether);
        // pay ticket
        if (!isDebug) {
            _eat.payF(_account, ticketsAmount);
        }
        // record pool
        _poolsInfo.game = _poolsInfo.game.add(_value.mul(87).div(100));
        _poolsInfo.endAward = _poolsInfo.endAward.add(_value.mul(5).div(100));
        _poolsInfo.community = _poolsInfo.community.add(_value.mul(6).div(100));
        _poolsInfo.tech = _poolsInfo.tech.add(_value.mul(2).div(100));
        // join game
        _pools[_account].amount = _pools[_account].amount.add(_value);
        _pools[_account].speed = _pools[_account].speed.add(_value);
        _poolsInfo.allSpeed = _poolsInfo.allSpeed.add(_value);
        if (_pools[_account].joinTime == 0) {
            _pools[_account].joinTime = _getDayTime(block.timestamp);
        }
        if (_pools[_account].amount >= 50 ether) {
            _pools[_account].releaseAmount = _pools[_account].releaseAmount.add(_value.mul(5));
        } else if (_pools[_account].amount >= 30 ether) {
            _pools[_account].releaseAmount = _pools[_account].releaseAmount.add(_value.mul(4));
        } else {
            _pools[_account].releaseAmount = _pools[_account].releaseAmount.add(_value.mul(3));
        }
        // get parent, check valid
        address parent = _referee[_account];
        if (_pools[_account].amount >= VALID_ACCOUNT_VALUE) {
            if (_validIndex[_account] == 0) {
                _validors[parent].push(_account); // update _validIndex
                _validIndex[_account] = _validors[parent].length;
                _pools[parent].validNum++; // update valid num
            }
        }
        // check speed
        for (uint i = 0; i < ACC_SPEED.length; i++) {
            if (parent == _root) {
                break;
            }
            if(_pools[parent].validNum > i) {
                // check valid num
                uint256 speed = _value.mul(ACC_SPEED[i]).div(100);
                _pools[parent].speed = _pools[parent].speed.add(speed);
                _poolsInfo.allSpeed = _poolsInfo.allSpeed.add(speed);
            }
            _pools[parent].community = _pools[parent].community.add(_value);
            // iterate
            parent = _referee[parent];
        }
    }

    /// upgradePartner
    function upgradePartner() external returns(uint) {
        _upgradePartner(msg.sender);
    }

    /// upgradePartner
    function _upgradePartner(address _account) private returns (uint) {
        require(_pools[_account].amount >= 50 ether, "EAGame: Your amount must larger than 50 ehter");
        uint len = _referrals[_account].length;
        uint256 first = 0;
        uint256 second = 0;
        for (uint i = 0; i < len; i++) {
            address temp = _referrals[_account][i];
            Pool memory pool = _pools[temp];
            uint256 all = pool.amount.add(pool.community);
            if (all >= first) {
                second = first;
                first = all;
            }
            if(all < first && all > second) {
                second = all;
            }
        }
        uint i = 0;
        for (i = 0; i < PARTNER_LEVEL_LIMIT.length; i++) {
            if (second < PARTNER_LEVEL_LIMIT[i]) {
                break;
            }
        }
        // partner add _account
        require(i > _pools[_account].level && i <= PARTNER_LEVEL_LIMIT.length, "EAGame: [upgradePartner] i illegal");
        // 获取历史等级
        uint level = _pools[_account].level;
        // 历史等级不为0，做个数修改
        if (level != 0) {
            if (_classesNum[level] > 0) {
                _classesNum[level] =  _classesNum[level] - 1;
            }
        } else {
            // 第一次进入
            _partners.push(_account);
        }
        _pools[_account].level = i;
        _classesNum[i] = _classesNum[i] + 1;
        return i;
    }

    /// sendPartner
    function sendPartner(uint256 gasUse) external onlyOwner {
        uint256 awardTotal = (_poolsInfo.community.sub(gasUse)).div(3);
        uint256 awardOne = 0;
        uint256 awardTwo = 0;
        uint256 awardThree = 0;
        uint256 alies = 0;
        if (_classesNum[1] > 0) {
            awardOne = awardTotal.div(_classesNum[1]);
        } else {
            alies = alies.add(awardTotal);
        }
        if (_classesNum[2] > 0) {
            awardTwo = awardTotal.div(_classesNum[2]);
        } else {
            alies = alies.add(awardTotal);
        }
        if (_classesNum[3] > 0) {
            awardThree = awardTotal.div(_classesNum[3]);
        } else {
            alies = alies.add(awardTotal);
        }
        for (uint i = 0; i < _partners.length; i++) {
            address a = _partners[i];
            if (_pools[a].level == 1) {
                address payable to = address(uint160(a));
                to.transfer(awardOne);
                _pools[a].partnerAmount = _pools[a].partnerAmount.add(awardOne);
            } else if (_pools[a].level == 2) {
                address payable to = address(uint160(a));
                to.transfer(awardTwo);
                _pools[a].partnerAmount = _pools[a].partnerAmount.add(awardTwo); 
            } else if (_pools[a].level == 3) {
                address payable to = address(uint160(a));
                to.transfer(awardThree);
                _pools[a].partnerAmount = _pools[a].partnerAmount.add(awardThree); 
            }
        }
        alies = alies.add(gasUse);
        msg.sender.transfer(alies);
        _poolsInfo.community = 0;
    }

    
    function partners() external view returns (address[] memory) {
        return _partners;
    }

    function setPartners(address[] calldata _p) external onlyOwner {
        _partners = _p;
    }

    function classesNum() external view returns (uint[4] memory) {
        return _classesNum;
    }

    function setClassesNum(uint[4] calldata _n) external onlyOwner {
        _classesNum = _n;
    }

    /// return _pools info
    function poolsInfo() public view returns(PoolsInfo memory) {
        return _poolsInfo;
    }

    /// return self pool info
    function pool(address _account) public view returns(Pool memory) {
        return _pools[_account];
    }

    function root()  public view returns(address) {
        return _root;
    }

    /// get speed
    function getSpeed() external view returns (uint8[12] memory) {
        return ACC_SPEED;
    }
    
    /// referee
    function referee(address _account) external view returns (address) {
        return _referee[_account];
    }

    /// referrals
    function referrals(address _account) external view returns(address[] memory) {
        return _referrals[_account];
    }

    function validors(address _account) external view returns(address[] memory) {
        return _validors[_account];
    }

    /// valid index
    function validIndex(address _account) external view returns(uint) {
        return _validIndex[_account];
    }
}
