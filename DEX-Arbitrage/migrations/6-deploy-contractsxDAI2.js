const TriArb = artifacts.require("../contracts/Execution/TriArbNoRD.sol");
const Optimizer = artifacts.require("../contracts/Opportunity/OptimizerTradeXDAI.sol");

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  deployer.deploy(TriArb).then(function() {
    return deployer.deploy(Optimizer, '0xA818b4F111Ccac7AA31D0BCc0806d64F2E0737D7', TriArb.address);
  });
};