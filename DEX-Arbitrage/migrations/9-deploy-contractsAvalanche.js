const TriArb = artifacts.require("../contracts/Execution/TriArbNoRD.sol");
const Optimizers = artifacts.require("../contracts/Opportunity/OptimizersReturn.sol");
const Uniswap = artifacts.require("../contracts/External/Uniswap.sol");
const Balancer = artifacts.require("../contracts/External/Balancer.sol");
const Optimizer = artifacts.require("../contracts/Opportunity/OptimizerReturn.sol");

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  deployer.deploy(Optimizers);
  deployer.link(Optimizers, Optimizer);
  deployer.deploy(TriArb);
  deployer.deploy(Optimizer, '0xefa94DE7a4656D787667C749f7E1223D71E9FD88');
};