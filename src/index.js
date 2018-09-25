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
web3.eth.accounts.wallet.add("0x35509c8e18e92d128ff5864b5576aa0f93879cc9059e8f142c33d454c8259ce8");
let BigNumber = require('bignumber.js');
const app = express();

let contract = new web3.eth.Contract(
  contractABI,
  contractAddress, {
    data: contractBytecode,
    from: web3.eth.accounts.wallet[0].address,
    gas: 300000,

  }
)
app
  .use(bodyParser.urlencoded({
    extended: false,
  }))
  .use(bodyParser.json())
  .use(cors());

app.post('/setWinner', async (req, res) => {
  const {
    matchId
  } = req.body;
  try {
    console.log(web3.eth.accounts.wallet[0].address);
    console.log('0xBc21125823F9A57A57B56e6fb4939D1f5A450f98')
    let matchContract = contract.methods;
    matchContract.getMatchWinner(matchId, matchId)
      .send({
        from: "0xBc21125823F9A57A57B56e6fb4939D1f5A450f98",
        // value: 1000000000000000,
        value: web3.utils.toHex(9000000000000000),
        // gas: 100000,
        // gasPrice:,
      }).then(async () => {
        let matchIndex = await matchContract.matchIdToId(matchId).call();
        let match = await matchContract.matches(matchIndex).call();
        res.send({
          match
        });
      })
  } catch (err) {
    console.log(err);
    res.status(400).send({
      msg: "err"
    })
  }
})

app.post('/getWinnings', async (req, res) => {
  const {
    address,
    matchId
  } = req.body;

  let matchIndex = await contract.methods.matchIdToId(matchId).call();
  let bets = await contract.methods.getOwnBets(matchId).call({
    from: address
  });
  let match = await contract.methods.matches(matchIndex).call();
  match = new Match(match);
  bets = {
    radiantBets: parseInt(bets['0']),
    direBets: parseInt(bets['1'])
  };

  let percentageOdd
  if (match.radiantWin) {
    percentageOdd = parseFloat((bets.radiantBets / parseInt(match.radiantBets)).toFixed(5));
  }
  if (match.direWin) {
    percentageOdd = parseFloat((bets.direBets / parseInt(match.direBets)).toFixed(5));
    // console.log( parseFloat((bets.direBets / parseInt(match.direBets)).toFixed(5)))
  }
  // I will take 1% of their winning to serve as compensation
  // console.log(percentageOdd)
  console.log(web3.eth.accounts.wallet[0].address == address)
  const winning = (parseInt(match.radiantBets) + parseInt(match.direBets)) * percentageOdd * .99;
  contract.methods.withdrawWinnings(matchId, winning.toString())
    .send({
      from: address,
      value: web3.utils.toHex(10000000000000000),
    }).then(async () => {
      match = await contract.methods.matches(matchIndex).send();
      res.status(200).send({
        match,
        matchIndex,
        bets
      });
    }).catch((err) => {
      console.log(err);
      res.status(400).send(err)
    })

})

app.get('/', (req, res) => {
  res.send("This is the Bounty Rune Server");
})


web3.eth.getBalance(contract.options.address).then(console.log)
app.listen(4001, () => console.log('Listening to 4001'))