const DSToken = artifacts.require("../contracts/DSToken.sol");

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {
  deployer.deploy(DSToken, 'L');
};