const Flashloan = artifacts.require("../contracts/Execution/Flashloan.sol");

const ABDK = artifacts.require("../contracts/Opportunity/ABDK.sol");
const ABDKFloat = artifacts.require("../contracts/Opportunity/ABDKFloat.sol");
const Optimizers = artifacts.require("../contracts/Opportunity/Optimizers.sol");
const Uniswap = artifacts.require("../contracts/Opportunity/Uniswap.sol");
const Balancer = artifacts.require("../contracts/Opportunity/Balancer.sol");
const optimalOpportunities = artifacts.require("../contracts/Opportunity/optimalOpportunities.sol");
const { mainnet: addresses } = require('../../addresses'); //Not sure why this shows as an error, this is the correct path

module.exports = function(deployer, _network, [beneficiaryAddress, _]) {

  //deployer.deploy(ABDK);
  //deployer.deploy(ABDKFloat);
  //deployer.link(ABDK, Uniswap);
  //deployer.link(ABDK, Balancer);
  //deployer.link(ABDK, Optimizers);
  //deployer.link(ABDKFloat, Optimizers);
  // deployer.deploy(Optimizers);
  // deployer.link(Optimizers, optimalOpportunities);
  // deployer.deploy(Uniswap);
  // deployer.deploy(Balancer);
  // deployer.link(Uniswap, optimalOpportunities);
  // deployer.link(Balancer, optimalOpportunities);
  // deployer.deploy(optimalOpportunities, '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f');
  //deployer.deploy(Flashloan);
};