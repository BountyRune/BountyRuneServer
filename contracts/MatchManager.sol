pragma solidity ^0.4.24;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "installed_contracts/oraclize-api/contracts/usingOraclize.sol";
import "./strings.sol";

contract MatchManager is Ownable, usingOraclize {
  event LogNewOraclizeQuery(string log);
  // String Lib. This lib will be use at getting MatchWinner that use oracle API
  using strings for *;
  
  struct Match {
        uint matchId;
        uint poolPrice;
        uint radiantBets;
        uint direBets;
        bool radiantWin;
        bool direWin;
        bool withdrawable;
        bool bettable;
        bool refundable;
        mapping(address => uint) betsOnRadiant;
        mapping(address => uint) betsOnDire;
        mapping(address => bool) hasBet;
        mapping(address => bool) winningsWithdraw;
    }
    
    mapping(address => bool) public addressIsAdmin;
    mapping(uint => uint) public matchIdToId;
    Match[] public matches;
    uint public selectedMatchId;
    
    constructor() payable public {
        // testing purposes
        // OAR = OraclizeAddrResolverI(0x6f485C8BF6fc43eA212E93BBF8ce046C7f1cb475);
        addressIsAdmin[msg.sender] = true;
    }
    
    // This will check if match is existing because if the result is 0, it means that match id has not data on the contract
    modifier matchNotExisting(uint matchId) {
        require(matchIdToId[matchId] == 0);
        _;
    }
    
    // Some function will require that only admin can access
    modifier onlyAdmin() {
        require(addressIsAdmin[msg.sender] == true);
        _;    
    }

    // check if match is ongoing
    modifier matchIsNotFinish(uint _matchId) {
        Match memory selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.radiantWin == false && selectedMatch.direWin == false);
        _;
    }
    
    // check if the match is finish
    modifier matchIsFinish(uint _matchId) {
        Match memory selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.radiantWin == true || selectedMatch.direWin == true);
        _;
    }

    //chech if the match is bettable and refunddable
    modifier matchNotStarted(uint _matchId) {
        Match memory selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.bettable == true);
        require(selectedMatch.refundable == true);
        _;
    }
    
    // check if the address has bet on the selected match
    modifier canBeBetted(uint _matchId, address _address) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.hasBet[_address] == false);
        _;
    }
    
    // check if the address had bet on the selected match
    modifier hasBetted(uint _matchId,address _address) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.hasBet[_address] == true);
        _;
    }

    // check if the address has withdraw his winnings on the selected match
     modifier canBeWithdraw(uint _matchId, address _address) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.winningsWithdraw[_address] == false);
        _;
    }

    // get number of matches    
    function matchesNumber() public view returns (uint) {
        return matches.length;
    }

    // change the roles of address to admin and normal and vice versa
    function changeRole(address _address) onlyAdmin public {
        addressIsAdmin[_address] = !addressIsAdmin[_address];
    }
    
    // add match
    function addMatch
    (
        uint _matchId
    ) 
        public
        matchNotExisting(_matchId)
        onlyAdmin
    {
        Match memory currentMatch;
        currentMatch.matchId = _matchId;
        // make the match bettable and refundable
        currentMatch.bettable = true;
        currentMatch.refundable = true;
        
        //convert it to index that corresponds to the match array length
        uint id = matches.push(currentMatch) - 1;
        matchIdToId[_matchId] = id;
    }
    
    // this will make the match unbettable in order to avoid cheating if the match is ongoing
    // if this function will call, all bets are lock until the match is over
    function startMatch(uint _matchId) public onlyAdmin {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        selectedMatch.bettable = false;
        selectedMatch.refundable = false;
    }
    
    // end the match, will make it withdrawable for those who one the tournament
    function endMatch(uint _matchId) public onlyAdmin {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        selectedMatch.withdrawable = true;
    }
    
    // this oracle function will get the result on the the Bounty Rune Bridge API
    // only admins can call this function
    function getMatchWinner(string _matchIdString, uint _matchIdUint) public payable onlyAdmin {
        // Oracle needs money to call its function
        if (oraclize_getPrice("URL") > address(this).balance) {
            revert("Not enough balance");
            emit LogNewOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit LogNewOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            // this one use the String library
            // Strings is serve as array so we call the toSlice() and concat to concatinate or add the other string;
            //
            // the query must be this json(https://bounty-rune-bridge.herokuapp.com/result/dota/4074748928).winner
            //
            string memory query = "json(https://bounty-rune-bridge.herokuapp.com/result/dota/".toSlice().concat(_matchIdString.toSlice());
            // same as where 
            string memory finalQuery = query.toSlice().concat(").winner".toSlice());
            selectedMatchId = _matchIdUint;
            oraclize_query("URL", finalQuery);
        }
    }
    
    // after calling the getMatchWinner 
    // this function will be called
    // it will set who won the match
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


