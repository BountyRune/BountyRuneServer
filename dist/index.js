'use strict';

function _asyncToGenerator(fn) { return function () { var gen = fn.apply(this, arguments); return new Promise(function (resolve, reject) { function step(key, arg) { try { var info = gen[key](arg); var value = info.value; } catch (error) { reject(error); return; } if (info.done) { resolve(value); } else { return Promise.resolve(value).then(function (value) { step("next", value); }, function (err) { step("throw", err); }); } } return step("next"); }); }; }

const express = require('express');
const axios = require('axios');
const bodyParser = require('body-parser');
const cors = require('cors');
const Web3 = require('web3');
const {
  contractABI,
  contractAddress,
  ropstenProvider,
  contractBytecode
} = require('../contractVariables');
const Match = require('./models/Match');
let web3 = new Web3(new Web3.providers.HttpProvider(ropstenProvider));
// Initialize Admin Account Address
web3.eth.accounts.wallet.add(process.env.privateKey);

const app = express();

let contract = new web3.eth.Contract(contractABI, contractAddress, {
  data: contractBytecode,
  from: web3.eth.accounts.wallet[0].address,
  gas: 300000
});
app.use(bodyParser.urlencoded({
  extended: false
})).use(bodyParser.json()).use(cors());

app.post('/setWinner', (() => {
  var _ref = _asyncToGenerator(function* (req, res) {
    const {
      matchId
    } = req.body;
    try {
      let matchContract = contract.methods;
      // This will get the match winner thru Oracle API. It is both the same because the first parameter
      // will be serve as string to and the other one will be uint
      // Check the contract for further information
      // Must pass some value in because calling an oracle function requires Eth
      matchContract.getMatchWinner(matchId, matchId).send({
        from: web3.eth.accounts.wallet[0].address,
        value: web3.utils.toHex(500000000000000000)
      }).then(_asyncToGenerator(function* () {
        // after successful retrieval of match
        // the contract will make the match withdrawable for those who won
        matchContract.endMatch(matchId).send({
          from: web3.eth.accounts.wallet[0].address,
          value: web3.utils.toHex(10000000000000000)
        }).then(_asyncToGenerator(function* () {
          // This is for sending the new match information
          let matchIndex = yield matchContract.matchIdToId(matchId).call();
          let match = yield matchContract.matches(matchIndex).call();
          res.send({
            match
          });
        }));
      }));
    } catch (err) {
      res.status(400).send({
        msg: "err"
      });
    }
  });

  return function (_x, _x2) {
    return _ref.apply(this, arguments);
  };
})());

app.post('/getWinnings', (() => {
  var _ref4 = _asyncToGenerator(function* (req, res) {
    const {
      address,
      matchId
    } = req.body;
    // get the match index from the contract
    let matchIndex = yield contract.methods.matchIdToId(matchId).call();
    // get your own get on the following match
    let bets = yield contract.methods.getOwnBets(matchId).call({
      from: address
    });
    // get match on the following index
    let match = yield contract.methods.matches(matchIndex).call();
    // make it into oop
    match = new Match(match);
    bets = {
      radiantBets: parseInt(bets['0']),
      direBets: parseInt(bets['1'])
    };

    let percentageOdd;
    // this part it will calculate the percentage of what you have won
    if (match.radiantWin) {
      percentageOdd = parseFloat((bets.radiantBets / parseInt(match.radiantBets)).toFixed(5));
    }
    if (match.direWin) {
      percentageOdd = parseFloat((bets.direBets / parseInt(match.direBets)).toFixed(5));
    }
    // I will take 1% of their winning to serve as compensation

    const winning = (parseInt(match.radiantBets) + parseInt(match.direBets)) * percentageOdd * .99;
    // then proceed to send their money back
    contract.methods.withdrawWinnings(matchId, winning.toString(), address).send({
      from: web3.eth.accounts.wallet[0].address,
      value: web3.utils.toHex(100000000000000000)
    }).then(_asyncToGenerator(function* () {
      match = yield contract.methods.matches(matchIndex).send();
      res.status(200).send({
        match,
        matchIndex,
        bets
      });
    })).catch(function (err) {
      res.status(400).send({ err: 'Error' });
    });
  });

  return function (_x3, _x4) {
    return _ref4.apply(this, arguments);
  };
})());

app.get('/', (req, res) => {
  res.send("This is the Bounty Rune Server");
});

app.listen(process.env.PORT || 4001, () => console.log('Listening to 4001'));