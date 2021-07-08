const TriArb = artifacts.require("../contracts/Execution/TriArb.sol");
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
  deployer.deploy(Optimizer, '0xEF45d134b73241eDa7703fa787148D9C9F4950b0');
  deployer.deploy(TriArb);
};