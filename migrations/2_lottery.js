var JackPotLottery = artifacts.require("./JackPotLottery.sol"); 

module.exports = function(deployer) {
  deployer.deploy(JackPotLottery, {gas: 4700000}); 
};
