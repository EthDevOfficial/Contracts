const TriArb = artifacts.require("../contracts/Execution/TriArbNoRD.sol");
const Optimizer = artifacts.require("../contracts/Opportunity/OptimizerTrade.sol");

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  //deployer.deploy(Optimizer, '0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32', '0x02118818e8068AEB63659728D70F039c8529E214');

  //deployer.deploy(TriArb).then(function() {
   deployer.deploy(Optimizer, '0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32', '0xc1d9eD1A5c2d16e19066E2aEC45246f026FA0bD6');
  //});
};