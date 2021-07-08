const TriArb = artifacts.require("../contracts/Execution/TriArbNoRD.sol");
const Optimizer = artifacts.require("../contracts/Opportunity/OptimizerTrade.sol");

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  //deployer.deploy(TriArb).then(function() {
    return deployer.deploy(Optimizer, '0xEF45d134b73241eDa7703fa787148D9C9F4950b0', '0x1Af15935BA8AFa61b2E37ca2b5926F133913fD1E');
  //});
};