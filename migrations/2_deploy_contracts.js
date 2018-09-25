let BettingManager = artifacts.require("./BettingManager.sol");
let MatchManager = artifacts.require("./MatchManager.sol");
let StringUtils = artifacts.require("./strings.sol");
let UsingOracle = artifacts.require("installed_contracts/oraclize-api/contracts/usingOraclize.sol");
let Ownable = artifacts.require(" openzeppelin-solidity/contracts/ownership/Ownable.sol");

module.exports = function(deployer, network, accounts) {

  // deployment steps
  // deployer.deploy(
  //     MyContract,
  //     { from: accounts[9], gas:6721975, value: 500000000000000000 }
  //   );
  deployer.deploy(StringUtils);
  deployer.deploy(UsingOracle);
  deployer.deploy(Ownable);
  deployer.link(Ownable, MatchManager);
  deployer.link(UsingOracle, MatchManager);
  deployer.link(StringUtils, MatchManager);
  deployer.deploy(MatchManager, 
    { from: accounts[9], gas:6721975, value: 500000000000000000 });
  deployer.link(MatchManager, BettingManager);
  deployer.deploy(BettingManager);

};