const ChiToken = artifacts.require("../contracts/External/ChiToken.sol");


module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  deployer.deploy(ChiToken);
};