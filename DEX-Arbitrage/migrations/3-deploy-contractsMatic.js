const TriArb = artifacts.require("../contracts/Execution/TriArbNoRD.sol");
const Optimizers = artifacts.require("../contracts/Opportunity/Optimizers.sol");
const Uniswap = artifacts.require("../contracts/External/Uniswap.sol");
const Balancer = artifacts.require("../contracts/External/Balancer.sol");
const Optimizer = artifacts.require("../contracts/Opportunity/Optimizer.sol");

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  deployer.deploy(Optimizers);
  deployer.link(Optimizers, Optimizer);
  deployer.deploy(Uniswap);
  deployer.deploy(Balancer);
  deployer.link(Uniswap, Optimizer);
  deployer.link(Balancer, Optimizer);
  deployer.deploy(Optimizer, '0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32');
  deployer.deploy(TriArb);
};