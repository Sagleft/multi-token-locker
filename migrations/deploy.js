// Make sure the DevToken contract is included by requireing it.
const myToken = artifacts.require("MultiLocker");

// THis is an async function, it will accept the Deployer account, the network, and eventual accounts.
module.exports = async function (deployer, network, accounts) {
  // await while we deploy the DevToken
  await deployer.deploy(myToken);
  const token = await myToken.deployed()
};
