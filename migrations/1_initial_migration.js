const DAO = artifacts.require("MyDAO");

module.exports = function (deployer) {
  deployer.deploy(DAO,10e20);
};
