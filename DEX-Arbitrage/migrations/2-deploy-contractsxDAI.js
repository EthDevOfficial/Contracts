const TriArb = artifacts.require("../contracts/Execution/TriArb.sol");
const Optimizers = artifacts.require("../contracts/Opportunity/OptimizersReturn.sol");
const Optimizer = artifacts.require("../contracts/Opportunity/OptimizerReturn.sol");

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  deployer.deploy(Optimizers);
  deployer.link(Optimizers, Optimizer);
  deployer.deploy(Optimizer, '0xA818b4F111Ccac7AA31D0BCc0806d64F2E0737D7');
  //deployer.deploy(TriArb);
};