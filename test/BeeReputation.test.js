var BeeReputation = artifacts.require("./BeeReputation.sol");
var BeeToken = artifacts.require("./BeeToken.sol");
var util = require("./util.js");


contract('BeeReputation Dispatch Test', function (accounts) {
    // account[0] points to the owner on the testRPC setup
    var owner = accounts[0];
    var user1 = accounts[1];
    var user2 = accounts[2];
    var user3 = accounts[3];
    var sudoPlatform = accounts[4];
    var tokenOwner = accounts[5];
    var uuid = "x";

    beforeEach(async function () {
        token = await BeeToken.new(user1, { from: tokenOwner });
        reputation = await BeeReputation.new(token.address, { from: owner });
    });

    it("Should allow users to pay Bee to increase their reputation", async function() {
        await token.enableTransfer({ from: tokenOwner });
        let isEnabled = await token.transferEnabled();
        assert(isEnabled, "transfers should be enabled");
        await token.transfer(user2, 1000, { from: tokenOwner });
        await token.transfer(user3, 1000, { from: tokenOwner });
        let user2Balance = (await token.balanceOf(user2)).toNumber();
        let user3Balance = (await token.balanceOf(user3)).toNumber();
        assert.equal(user2Balance, 1000);
        assert.equal(user3Balance, 1000);

        await token.approve(reputation.address, 100, { from: user2 });

        await reputation.boostReputationWithBees(100, { from: user2 });
        let balanceCheck = (await token.balanceOf(reputation.address)).toNumber();
        assert.equal(balanceCheck, 100);
    });

    it("Should allow owner to withdraw Bees", async function() {
        await token.enableTransfer({ from: tokenOwner });
        let isEnabled = await token.transferEnabled();
        assert(isEnabled, "transfers should be enabled");
        await token.transfer(user2, 1000, { from: tokenOwner });
        await token.transfer(user3, 1000, { from: tokenOwner });
        let user2Balance = (await token.balanceOf(user2)).toNumber();
        let user3Balance = (await token.balanceOf(user3)).toNumber();
        assert.equal(user2Balance, 1000);
        assert.equal(user3Balance, 1000);

        await token.approve(reputation.address, 100, { from: user2 });

        await reputation.boostReputationWithBees(100, { from: user2 });
        let balanceCheck = (await token.balanceOf(reputation.address)).toNumber();
        assert.equal(balanceCheck, 100);

        await reputation.ownerWithdrawBee({ from: owner });
        let ownerBalance = (await token.balanceOf(owner)).toNumber();
        assert.equal(ownerBalance, 100);
    });

    it("Should allow owner to withdraw ether donations", async function() {
        await reputation.sendTransaction({ value: util.oneEther, from: user2 });
        var repAddress = await reputation.address;
        var ethBalance = (await web3.eth.getBalance(repAddress)).toNumber();
        await reputation.ownerWithdrawEther();
        assert.equal(ethBalance, 1000000000000000000);
        var ethBalance = (await web3.eth.getBalance(repAddress)).toNumber();
        assert.equal(ethBalance, 0);
    });

    it("Should add new reputation score", async function() {
        await reputation.updateReputation(sudoPlatform, uuid, 50, { from: owner });
        var repScore = (await reputation.reputation(uuid, sudoPlatform)).toNumber();
        assert.equal(repScore, 50);
    });

    it("Should update reputation score", async function() {
        await reputation.updateReputation(sudoPlatform, uuid, 50, { from: owner });
        await reputation.updateReputation(sudoPlatform, uuid, 60, { from: owner });
        var repScore = (await reputation.reputation(uuid, sudoPlatform)).toNumber();
        assert.equal(repScore, 60);
    });

    //TODO: should allow owner to withdraw ether
    //TODO: should allow owner to update new platforms
    //TODO: should allow owner to add new admins
    //TODO: should not allow non-admins/owner update scores
    //TODO: should allow admin to update platform rep scores
    //TODO should not admins to update other platforms
});
