pragma solidity ^0.4.24;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "installed_contracts/oraclize-api/contracts/usingOraclize.sol";
import "./strings.sol";

contract MatchManager is Ownable, usingOraclize {
  event LogNewOraclizeQuery(string log);
  using strings for *;
  
  struct Match {
        uint matchId;
        uint totalBets;
        uint radiantBets;
        uint direBets;
        uint startTime;
        bool radiantWin;
        bool direWin;
        bool withdrawable;
        bool bettable;
        bool refundable;
        mapping(address => uint) betsOnRadiant;
        mapping(address => uint) betsOnDire;
        mapping(address => bool) winningsWithdraw;
    }
    
    
    mapping(address => bool) public addressIsAdmin;
    mapping(uint => uint) public matchIdToId;
    Match[] public matches;
    uint public selectedMatchId;
    
    constructor() payable public {
        OAR = OraclizeAddrResolverI(0x0eDDc9C6BB90017481A716b05176303B9DB14BB3);
        addressIsAdmin[msg.sender] = true;
    }

    function() public {
        revert();
    }
    
    modifier matchNotExisting(uint matchId) {
        require(matchIdToId[matchId] == 0);
        _;
    }
    
    modifier onlyAdmin() {
        require(addressIsAdmin[msg.sender] == true);
        _;    
    }

    modifier matchIsNotFinish(uint _matchId) {
        Match memory selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.radiantWin == false && selectedMatch.direWin == false);
        _;
    }
    
    modifier matchIsFinish(uint _matchId) {
        Match memory selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.radiantWin == true || selectedMatch.direWin == true);
        _;
    }

    modifier matchNotStarted(uint _matchId) {
        Match memory selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.bettable == true);
        require(selectedMatch.refundable == true);
        _;
    }
   
    function matchesNumber() public view returns (uint) {
        return matches.length;
    }

    function changeRole(address _address) onlyAdmin public {
        addressIsAdmin[_address] = !addressIsAdmin[_address];
    }
    
    function addMatch
    (
        uint _matchId,
        uint _startTime
    ) 
        public
        matchNotExisting(_matchId)
        onlyAdmin
    {
        Match memory currentMatch;
        currentMatch.matchId = _matchId;
        currentMatch.bettable = true;
        currentMatch.refundable = true;
        currentMatch.startTime = _startTime;
        
        uint id = matches.push(currentMatch) - 1;
        matchIdToId[_matchId] = id;
    }
    
    function startMatch(uint _matchId) public onlyAdmin {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        selectedMatch.bettable = false;
        selectedMatch.refundable = false;
    }
    
    function endMatch(uint _matchId, bool _radiantWin) public onlyAdmin {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        selectedMatch.withdrawable = true;
    }
    
    function getMatchWinner(string _matchIdString, uint _matchIdUint) public payable {
        if (oraclize_getPrice("URL") > address(this).balance) {
            revert("Not enough balance");
            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            string memory query = "json(https://bounty-rune-bridge.herokuapp.com/result/dota/".toSlice().concat(_matchIdString.toSlice());
            string memory finalQuery = query.toSlice().concat(").winner".toSlice());
            selectedMatchId = _matchIdUint;
            oraclize_query("URL", finalQuery);
        }
    }
    
    function __callback(bytes32 myid, string result) {
        require(msg.sender == oraclize_cbAddress());
        require(keccak256(result) != keccak256(""));
         Match storage selectedMatch = matches[matchIdToId[selectedMatchId]];
        if(keccak256(result) == keccak256('Radiant')) {
            selectedMatch.radiantWin = true;
        } else if (keccak256(result) == keccak256('Dire')){
            selectedMatch.direWin = true;
        }
        selectedMatch.withdrawable = true;
  }

}


