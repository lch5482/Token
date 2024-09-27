const SLToken = artifacts.require("SLToken");

module.exports = function (deployer) {
  const fundBuilder = "0xAddress1";             // Replace with the actual address
  const teamMember = "0xAddress2";              // Replace with the actual address
  const coreBuilder = "0xAddress3";             // Replace with the actual address
  const ecosystemTreasury = "0xAddress4";       // Replace with the actual address
  const liquidityAndStakingPool = "0xAddress5"; // Replace with the actual address
  const marketingAllocation = "0xAddress6";     // Replace with the actual address
  const foundationTreasury = "0xAddress7";      // Replace with the actual address

  deployer.deploy(SLToken, fundBuilder, teamMember, coreBuilder, ecosystemTreasury, liquidityAndStakingPool, marketingAllocation, foundationTreasury);
};
