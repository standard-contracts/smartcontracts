var BeeReputation = artifacts.require("./BeeReputation.sol");
var BeeToken = artifacts.require("./BeeToken.sol");
var util = require("./util.js");

contract('BeeReputation Dispatch Test', function (accounts) {
    // account[0] points to the owner on the testRPC setup
    var owner = accounts[0];
    var user1 = accounts[1];
    var user2 = accounts[2];
    var user3 = accounts[3];

    beforeEach(async function () {
        token = await BeeToken.new(user1, { from: owner });
        reputation = await BeeReputation.new();
    });

    it("Should pass", async function() {
        assert(true);
    })
});
