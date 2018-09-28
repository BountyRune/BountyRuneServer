pragma solidity ^0.4.24;

import "./MatchManager.sol";

contract BettingManager is MatchManager {
    // Will bet on the selected team
    // it can bet if the match is not yet started or the user hasnt bet yet
    function bet(uint _matchId, bool _onRadiant) payable public 
    matchNotStarted(_matchId) canBeBetted(_matchId, msg.sender) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        // will choose what team to bet on
        if (_onRadiant) {
            selectedMatch.betsOnRadiant[msg.sender] += msg.value;
            selectedMatch.radiantBets += msg.value;
        } else {
            selectedMatch.betsOnDire[msg.sender] += msg.value;
            selectedMatch.direBets += msg.value;
        }
        // After betting the pool price will rise up
        selectedMatch.poolPrice += msg.value;
        // after betting it will tell that this address has bet so that he cant bet on the other team
        selectedMatch.hasBet[msg.sender] = true;
    }
    
    // return your bets
    function getOwnBets(uint _matchId) public view returns (uint, uint) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        return (selectedMatch.betsOnRadiant[msg.sender], selectedMatch.betsOnDire[msg.sender]);
    }
    
    // if you decide to change your team or to cancel your bet
    // the match must be yet not started in order to avoid cheating
    function refund(uint _matchId, bool _onRadiant, address _address) 
        public payable  hasBetted(_matchId, _address) {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        uint currentBet;
        if (_onRadiant) {
            currentBet = selectedMatch.betsOnRadiant[_address];
            selectedMatch.radiantBets -= currentBet;
            selectedMatch.betsOnRadiant[_address] = 0;   
        } else {
            currentBet = selectedMatch.betsOnDire[_address];
            selectedMatch.direBets -= currentBet;
            selectedMatch.betsOnDire[_address] = 0;
 
        }
        selectedMatch.hasBet[_address] = false;
        selectedMatch.poolPrice -= currentBet;
        _address.transfer(currentBet);
    }

    // Withdraw winnings, only admin can transfer winnings in order to avoid cheating
    function withdrawWinnings(uint _matchId, uint _amountWithdraw, address _address) 
        public 
        payable 
        canBeWithdraw(_matchId, _address)
        hasBetted(_matchId, _address)
        onlyAdmin
        {
        Match storage selectedMatch = matches[matchIdToId[_matchId]];
        require(selectedMatch.radiantWin == true || selectedMatch.direWin == true);
        require(
            selectedMatch.betsOnRadiant[_address] >= _amountWithdraw ||
            selectedMatch.betsOnDire[_address] >= _amountWithdraw ||
            selectedMatch.poolPrice >= _amountWithdraw
         );
        selectedMatch.winningsWithdraw[_address] = true;
        _address.transfer(_amountWithdraw);
        selectedMatch.poolPrice -= _amountWithdraw;
    }
    
    // Withdraw the compensation
    function getRemainingPricePool(uint _matchId)
        public
        payable 
        onlyAdmin {
            Match storage selectedMatch = matches[matchIdToId[_matchId]];
            msg.sender.transfer(selectedMatch.poolPrice);
        }
}

