const Web3 = require('web3');
const { contractABI, contractAddress, ropstenProvider, contractBytecode } = require('../../contractVariables');
let web3 = new Web3(new Web3.providers.HttpProvider(ropstenProvider));

class Match {
	constructor(docs) {
		Object.assign(this, docs);
	}

	get getRadiantBetsToEth() {
		return web3.utils.fromWei(this.radiantBets);
	}

	get getDireBetsToEth() {
		return web3.utils.fromWei(this.direBets);
	}

	get totalBetsToEth() {
		return web3.utils.fromWei(this.totalBets);
	}

	totalWinningPercentage(bet, teamBet, otherTeamBet)  {
		const percentage = (bet / teamBet);
		const winning = percentage * otherTeamBet;
		return winning;
	}
}

module.exports = Match;