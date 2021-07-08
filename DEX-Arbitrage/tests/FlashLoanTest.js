const FlashLoan = artifacts.require("FlashLoan");
//const web3 = require('web3');

contract("FlashLoan", async accounts => {

  // it("Should return hello world", async() => {
  //   let instance = await FlashLoan.deployed();
  //   let output = await instance.sayHello.call();

  //   assert.equal(
  //       output,
  //       "hello world",
  //       "Does not return hello world correctly"
  //     );

  // });

  // it("Test add token permission", async() => {
  //   let instance = await FlashLoan.deployed();
  //     //DAI Ropsten address
  //     await instance.addNewToken.call("0xad6d458402f60fd3bd25163575031acdce07538d");
  //   });



  //   it('Contract balance should starts with 0 ETH', async () => {
  //     let instance = await FlashLoan.deployed();
  //     let balance = await web3.eth.getBalance(instance.address);
  //     let balance2 = await instance.checkBalance.call();
  //     assert.equal(balance, 0);
  //     assert.equal(balance2, 0);
  // })



  // it('Uniswap trade test', async () => {
  //   let instance = await FlashLoan.deployed();

  //   //Deposit .001 eth
  //   let one_eth = web3.utils.toWei(".001");
  //   await web3.eth.sendTransaction({ from: accounts[0], to: instance.address, value: one_eth });

  //   //Withdraw Eth
  //   await instance.withdrawEth();

  //   //Check Balance
  //   let balance_wei_after = await web3.eth.getBalance(instance.address);
  //   let balance_ether_after = web3.utils.fromWei(balance_wei_after);
  //   assert.equal(balance_ether_after, 0);
  // })

  // it('FlashLoan token balance should be 0 after withdraw', async () => {
  //   let instance = await FlashLoan.deployed();

  //   //Deposit .001 eth
  //   let one_eth = web3.utils.toWei(".01");
  //   await web3.eth.sendTransaction({ from: accounts[0], to: instance.address, value: one_eth });



  //   await instance.addNewToken("0xad6d458402f60fd3bd25163575031acdce07538d");
  //   await instance.addNewToken("0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984");
  //   await instance.addNewToken("0xc778417e063141139fce010982780140aa0cd5ab");

  //   await instance.tradeOnUniswap("0xc778417e063141139fce010982780140aa0cd5ab", "0xad6d458402f60fd3bd25163575031acdce07538d", web3.utils.toBN(web3.utils.toWei('.01')));
 

  //   await instance.tradeOnUniswap("0xad6d458402f60fd3bd25163575031acdce07538d", "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984", web3.utils.toBN(web3.utils.toWei('.01')));

  //   await instance.withdrawEth();
  //   await instance.withdrawErc20("0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984");


    
  //   console.log("done");
  // })

  it('Kyber trade test', async () => {
    let instance = await FlashLoan.at("0xF60baF88F92FC43B70C11e6B7Af169934D0405e2");

    //Deposit .001 eth
    //let one_eth = web3.utils.toWei(".1");
    //await web3.eth.sendTransaction({ from: accounts[0], to: instance.address, value: one_eth });



   // await instance.addNewToken("0xad6d458402f60fd3bd25163575031acdce07538d");  //DAI
   // await instance.addNewToken("0x7b2810576aa1cce68f2b118cef1f36467c648f92"); //KNC
   // await instance.addNewToken("0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984"); //UNI
  //  await instance.addNewToken("0xc778417E063141139Fce010982780140Aa0cD5Ab"); //Weth

  //  await instance.sellEth("0xc778417E063141139Fce010982780140Aa0cD5Ab", "0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984");

    //await instance.tradeOnUniswap("0xbCA556c912754Bc8E7D4Aad20Ad69a1B1444F42d", "0xaD6D458402F60fD3Bd25163575031ACDce07538D", web3.utils.toBN(web3.utils.toWei('.1')));
 
    await instance.tradeOnKyber("0xaD6D458402F60fD3Bd25163575031ACDce07538D", "0xbCA556c912754Bc8E7D4Aad20Ad69a1B1444F42d", web3.utils.toBN(web3.utils.toWei('10')));
    //await instance.tradeOnKyber("0xad6d458402f60fd3bd25163575031acdce07538d", "0x7b2810576aa1cce68f2b118cef1f36467c648f92", web3.utils.toBN(web3.utils.toWei('1.1')));

    //await instance.withdrawEth();
   // await instance.withdrawErc20("0xbCA556c912754Bc8E7D4Aad20Ad69a1B1444F42d");


    
    console.log("done");
  })

  // it('Mainnet Full Test', async () => {
  //   let instance = await FlashLoan.at("0x4222E1681a7C3AD2055735CE62Fa9BFBD3da1A4D");
  //   const DIRECTION = {
  //     KYBER_TO_UNISWAP: 0,
  //     UNISWAP_TO_KYBER: 1
  //   };
  //   //Deposit .001 eth
  //   //let one_eth = web3.utils.toWei(".1");
  //   //await web3.eth.sendTransaction({ from: accounts[0], to: instance.address, value: one_eth });



  //   //await instance.addNewToken("0x6B175474E89094C44Da98b954EedeAC495271d0F");  //DAI
  //   //await instance.addNewToken("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"); //Weth

  //   //console.log("Added tokens");

  //   await instance.initiateFlashLoan("0x1E0447b19BB6EcFdAe1e4AE1694b0C3659614e4e", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "0x6B175474E89094C44Da98b954EedeAC495271d0F", web3.utils.toBN(web3.utils.toWei('1')), DIRECTION.UNISWAP_TO_KYBER);

  //   console.log("Executed Flashloan");


  //   console.log("done");
  // })


});


