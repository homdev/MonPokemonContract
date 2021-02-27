const MonPokemon = artifacts.require("MonPokemon");

module.exports = function(deployer, _network, accounts) {
  deployer.deploy(MonPokemon, {from: accounts[1]});
};
