var BeeReputation = artifacts.require("./BeeReputation.sol");
var BeeToken = artifacts.require("./BeeToken.sol");
var util = require("./util.js");


contract('BeeReputation Test', function (accounts) {
    // account[0] points to the owner on the testRPC setup
    var owner = accounts[0];
    var user1 = accounts[1];
    var user2 = accounts[2];
    var user3 = accounts[3];
    var sudoPlatform = accounts[4];
    var tokenOwner = accounts[5];
    var tokenPrice = 10000000000000000000;
    var uuid = "x";

    beforeEach(async function () {
        token = await BeeToken.new(user1, { from: tokenOwner });
        reputation = await BeeReputation.new(token.address, tokenPrice, { from: owner });
    });

    it("Should allow users to pay Bee to increase their reputation", async function() {
        await token.enableTransfer({ from: tokenOwner });
        let isEnabled = await token.transferEnabled();
        assert(isEnabled, "transfers should be enabled");
        await token.transfer(user2, 10000000000000000000, { from: tokenOwner });
        await token.transfer(user3, 10000000000000000000, { from: tokenOwner });
        let user2Balance = (await token.balanceOf(user2)).toNumber();
        let user3Balance = (await token.balanceOf(user3)).toNumber();
        assert.equal(user2Balance, 10000000000000000000);
        assert.equal(user3Balance, 10000000000000000000);
        await reputation.updateReputation(sudoPlatform, uuid, 50, { from: owner });
        
        var repScore = (await reputation.reputation(uuid, sudoPlatform)).toNumber();
        assert.equal(repScore, 50);

        await token.approve(reputation.address, 10000000000000000000, { from: user2 });

        await reputation.boostReputationWithBees(sudoPlatform, uuid, { from: user2 });
        let balanceCheck = (await token.balanceOf(reputation.address)).toNumber();
        var repScore = (await reputation.reputation(uuid, sudoPlatform)).toNumber();
        assert.equal(repScore, 51);
        assert.equal(balanceCheck, 10000000000000000000);
    });

    it("Should allow owner to withdraw Bees", async function() {
        await token.enableTransfer({ from: tokenOwner });
        let isEnabled = await token.transferEnabled();
        assert(isEnabled, "transfers should be enabled");
        await token.transfer(user2, 10000000000000000000, { from: tokenOwner });
        await token.transfer(user3, 10000000000000000000, { from: tokenOwner });
        let user2Balance = (await token.balanceOf(user2)).toNumber();
        let user3Balance = (await token.balanceOf(user3)).toNumber();
        assert.equal(user2Balance, 10000000000000000000);
        assert.equal(user3Balance, 10000000000000000000);
        await reputation.updateReputation(sudoPlatform, uuid, 50, { from: owner });

        var repScore = (await reputation.reputation(uuid, sudoPlatform)).toNumber();
        assert.equal(repScore, 50);

        await token.approve(reputation.address, 10000000000000000000, { from: user2 });

        await reputation.boostReputationWithBees(sudoPlatform, uuid, { from: user2 });
        let balanceCheck = (await token.balanceOf(reputation.address)).toNumber();
        var repScore = (await reputation.reputation(uuid, sudoPlatform)).toNumber();
        assert.equal(repScore, 51);
        assert.equal(balanceCheck, 10000000000000000000);
        await reputation.ownerWithdrawBee({ from: owner });
        let ownerBalance = (await token.balanceOf(owner)).toNumber();
        assert.equal(ownerBalance, 10000000000000000000);
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

    it("Should read reputation score", async function() {
        await reputation.updateReputation(sudoPlatform, uuid, 50, { from: owner });
        var repScore = (await reputation.checkPlatfomReputation(sudoPlatform, uuid)).toNumber();
        assert.equal(repScore, 50);
    });

    it("Should read score 0 of non existant platform", async function() {
        await reputation.updateReputation(sudoPlatform, uuid, 50, { from: owner });
        var repScore = (await reputation.checkPlatfomReputation(owner, uuid)).toNumber();
        assert.equal(repScore, 0);
    });

    it("Should read score 0 of non existant user", async function() {
        await reputation.updateReputation(sudoPlatform, uuid, 50, { from: owner });
        var repScore = (await reputation.checkPlatfomReputation(sudoPlatform, "hi")).toNumber();
        assert.equal(repScore, 0);
    });

    it("Should read score 0 if both platform and user do not exist", async function() {
        var repScore = (await reputation.checkPlatfomReputation(sudoPlatform, "hi")).toNumber();
        assert.equal(repScore, 0);
    });

    //TODO: should allow owner to update new platforms
    //TODO: should allow owner to add new admins
    //TODO: should not allow non-admins/owner update scores
    //TODO: should allow admin to update platform rep scores
    //TODO: should not allow admins to update other platforms
});
