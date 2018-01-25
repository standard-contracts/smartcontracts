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
        reputation = await BeeReputation.new(token.address, { from: owner });
    });

    it("Should allow users to pay Bee to increase their reputation", async function() {
        await token.enableTransfer();
        let isEnabled = await token.transferEnabled();
        assert(isEnabled, "transfers should be enabled");
        await token.transfer(user2, 1000, { from: owner });
        await token.transfer(user3, 1000, { from: owner });
        let user2Balance = (await token.balanceOf(user2)).toNumber();
        let user3Balance = (await token.balanceOf(user3)).toNumber();
        assert.equal(user2Balance, 1000);
        assert.equal(user3Balance, 1000);

        await token.approve(reputation.address, 100, { from: user2 });

        await reputation.boostReputationWithBees(100, { from: user2 });
        let balanceCheck = (await token.balanceOf(reputation.address)).toNumber();
        assert.equal(balanceCheck, 100)

    })
    //TODO: should allow owner to withdraw ether
    //TODO: should allow owner to withdraw Bee
    //TODO: should allow owner to update new platforms
    //TODO: should allow owner to add new admins
    //TODO: should not allow non-admins/owner update scores
    //TODO: should allow admin to update platform rep scores
    //TODO should not admins to update other platforms
    //
});
