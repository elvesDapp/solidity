pragma solidity >=0.4.2 <0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval( address indexed owner, address indexed spender, uint256 value );
}
interface IElvinv {
    function supReturn(address account) external view returns (address);
}
interface IElvBuyNft {
    function userPower(address account) external view returns (uint);
    function userContributionValue(address account) external view returns (uint);
    function userTeamPower(address account) external view returns (uint);
    function userTeamPowerA(address account) external view returns (uint);
    function userTeamPowerB(address account) external view returns (uint);
    function userTeamPowerC(address account) external view returns (uint);
    function userTeamPowerD(address account) external view returns (uint);
}

contract ElvProfit{
    address public _owner;
    uint public _nftIndex1;
    uint public _nftIndex2;
    IElvinv public _invContractAddress;
    IElvBuyNft public _elvBuyNftAddress;
    IERC20 public _elvToken;
    uint public _startTime;
    uint public _day;

    constructor(IElvinv invContractAddress,IElvBuyNft elvBuyNftAddress,IERC20 elvToken) public {
      _owner = msg.sender;
      _invContractAddress = invContractAddress;
      _elvBuyNftAddress = elvBuyNftAddress;
      _elvToken = elvToken;
      _startTime = now;
      _day = 86400;
    }
    event userReward(address indexed from,uint amount,uint timestamp);
    event userTeamReward(address indexed from,uint amount,uint timestamp);

    struct Pledgor{
        uint allUserAmount;
        uint allTeamAmount;
        uint lastUserTime;
        uint lastTeamTime;
    }
    Pledgor[] public pledgor;
    mapping(address => Pledgor) public pledgors;

    function update(IERC20 elvToken,uint startTime) public{
      require(msg.sender == _owner, "No way to extract");
      _elvToken = elvToken;
      _startTime = startTime;
    }
    function supReturn(address addr) public view returns (address){
        return _invContractAddress.supReturn(addr);
    }
    function lastUserTimeReturn(address addr) public view returns (uint){
        return pledgors[addr].lastUserTime;
    }
    function lastTeamTimeReturn(address addr) public view returns (uint){
        return pledgors[addr].lastTeamTime;
    }
    function addrArrUpdate (address[] memory addrArr,uint[] memory lastUserTimeArr,uint[] memory lastTeamTimeArr
      ) public{
        require(msg.sender == _owner, "No way to extract");
        for(uint i = 0;i < addrArr.length;i++){
            pledgors[addrArr[i]].lastUserTime = lastUserTimeArr[i];
            pledgors[addrArr[i]].lastTeamTime = lastTeamTimeArr[i];
        }
    }
    function earned(address addr) public view returns(uint) {
        uint power = _elvBuyNftAddress.userPower(addr);
        if(power != 0){
            uint _timestamps = now;
            uint userLastTime;
            if(pledgors[addr].lastUserTime == 0){
              userLastTime = _startTime;
            }else{
              userLastTime = pledgors[addr].lastUserTime;
            }
            uint profit = power / 86400 * (_timestamps - userLastTime) * 10**8 / 100000;
            return profit;
        } else {
            return 0;
        }
    }
    function earnedTeam(address account,address[] memory childList) public view returns(uint) {
        uint contributionValue = _elvBuyNftAddress.userContributionValue(account);
        if( contributionValue > 0){
          uint _timestamps = now;
          uint userLastTime;
          if(pledgors[account].lastTeamTime == 0){
            userLastTime = _startTime;
          }else{
            userLastTime = pledgors[account].lastTeamTime;
          }
          uint childPowers = 0;
          uint regionAllPower = 0;
          uint regionPower = 0;
          uint diff = 0;
          for(uint i = 0;i < childList.length;i ++){
            require(account == supReturn(childList[i]));
            childPowers += _elvBuyNftAddress.userPower(childList[i]);
            regionAllPower += _elvBuyNftAddress.userTeamPower(childList[i]);
            if(diff < _elvBuyNftAddress.userTeamPower(childList[i])){
              diff = _elvBuyNftAddress.userTeamPower(childList[i]);
            }
          }
          if(childList.length <= 1){
            regionPower = 0;
          } else {
            regionPower = (regionAllPower - diff)/100000;
          }
          if(contributionValue < 5){
            return childPowers * 10**8 / _day * (_timestamps - userLastTime) / 50;
          } else{
               if(regionPower >= 4000){
                  if(contributionValue >= 5 && contributionValue < 10 && regionPower >= 4000){
                    return _elvBuyNftAddress.userTeamPowerA(account) * 10**8  / _day * (_timestamps - userLastTime)/ 50 ;
                  }
                  if(contributionValue >= 10 && contributionValue < 15 && regionPower >= 12000){
                    return _elvBuyNftAddress.userTeamPowerB(account) * 10**8 / _day *(_timestamps - userLastTime) / 50;
                  }
                  if(contributionValue >= 15 && contributionValue < 20 && regionPower >= 96000){
                    return _elvBuyNftAddress.userTeamPowerC(account) * 10**8 / _day *(_timestamps - userLastTime) / 50 ;
                  }
                  if(contributionValue >= 20 && contributionValue < 30 && regionPower >= 240000){
                    return _elvBuyNftAddress.userTeamPowerD(account) * 10**8 / _day * (_timestamps - userLastTime) / 50;
                  }
              } else{
                  return childPowers * 10**8 / _day * (_timestamps - userLastTime) / 50;
              }
          }
        } else {
          return 0;
        }
    }
    function getUserReward() public {
        uint p = earned(msg.sender);
        uint _timestamps = now;
        _elvToken.transfer(msg.sender, p);
        pledgors[msg.sender].lastUserTime = _timestamps;
        pledgors[msg.sender].allUserAmount += p;
        emit userReward(msg.sender,p,_timestamps);
    }
     function getTeamReward(address[] memory childList) public {
         for(uint i = 0;i < childList.length;i ++ ){
             uint flag = 0;
             for(uint c = 0;c < childList.length;c ++ ){
                if(childList[i] == childList[c]){
                    flag += 1;
                    require(flag <= 1);
                }
             }
         }
        uint p = earnedTeam(msg.sender,childList) / 100000;
        uint _timestamps = now;
        _elvToken.transfer(msg.sender, p);
        pledgors[msg.sender].lastTeamTime = _timestamps;
        pledgors[msg.sender].allTeamAmount += p;
        emit userTeamReward(msg.sender,p,_timestamps);
    }

    
  }
