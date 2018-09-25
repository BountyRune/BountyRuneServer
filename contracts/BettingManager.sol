pragma solidity ^0.4.24;

import "./MatchManager.sol";

contract BettingManager is MatchManager {
    function bet(uint _matchId, bool _onRadiant) payable public matchNotStarted(_matchId) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        if (_onRadiant) {
            selectedMatch.betsOnRadiant[msg.sender] += msg.value;
            selectedMatch.radiantBets += msg.value;
        } else {
            selectedMatch.betsOnDire[msg.sender] += msg.value;
            selectedMatch.direBets += msg.value;
        }
        selectedMatch.totalBets += msg.value;
    }
    
    function getOwnBets(uint _matchId) public view returns (uint, uint) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        return (selectedMatch.betsOnRadiant[msg.sender], selectedMatch.betsOnDire[msg.sender]);
    }
    
    function getTeamBets(uint _matchId) public view returns (uint, uint) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        return (selectedMatch.radiantBets, selectedMatch.direBets);
    }
    
    function refund(uint _matchId, bool _onRadiant) public payable {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        uint currentBet;
        if (_onRadiant) {
            currentBet = selectedMatch.betsOnRadiant[msg.sender];
            selectedMatch.radiantBets -= currentBet;
            selectedMatch.betsOnRadiant[msg.sender] = 0;
            
        } else {
            currentBet = selectedMatch.betsOnDire[msg.sender];
            selectedMatch.direBets -= currentBet;
            selectedMatch.betsOnDire[msg.sender] = 0;
 
        }
        selectedMatch.totalBets -= currentBet;
        msg.sender.transfer(currentBet);
    }
    
    function setBets(uint _matchId) public payable {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.radiantWin == true || selectedMatch.direWin == true);
        if(selectedMatch.radiantWin == true) {
            selectedMatch.radiantBets += selectedMatch.direBets;
            selectedMatch.direBets = 0;
        }
        if(selectedMatch.direWin == true) {
            selectedMatch.direBets += selectedMatch.radiantBets;
            selectedMatch.radiantBets = 0;
        }
    }
    
    function setBetsTest(uint _matchId, bool _result) public {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        // require(selectedMatch.radiantWin == true || selectedMatch.direWin == true);
        if(_result == true) {
            selectedMatch.radiantBets += selectedMatch.direBets;
            selectedMatch.direBets = 0;
        }
        if(_result == false) {
            selectedMatch.direBets += selectedMatch.radiantBets;
            selectedMatch.radiantBets = 0;
        }
    }
    

    function withdrawWinnings(uint _matchId, uint _amountWithdraw) public payable {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.radiantWin == true || selectedMatch.direWin == true);
        msg.sender.transfer(_amountWithdraw);
        selectedMatch.totalBets -= _amountWithdraw;
        if(selectedMatch.radiantWin == true) {
            selectedMatch.radiantBets -= _amountWithdraw;
        }
        if(selectedMatch.direWin == true) {
            selectedMatch.direBets -= _amountWithdraw;
        }
    }
    
    function withdrawTesetWinnings(uint _matchId, uint _amountWithdraw, bool result) public payable {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        // require(selectedMatch.radiantWin == true || selectedMatch.direWin == true);
        msg.sender.transfer(_amountWithdraw);
        selectedMatch.totalBets -= _amountWithdraw;
        if(result == true) {
            selectedMatch.radiantBets -= _amountWithdraw;
        }
        if(result == false) {
            selectedMatch.direBets -= _amountWithdraw;
        }
        selectedMatch.winningsWithdraw[msg.sender] = true;
    }
}