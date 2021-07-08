const Multicall = artifacts.require("../contracts/Opportunity/Multicall.sol");

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  deployer.deploy(Multicall);
};