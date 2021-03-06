const MatchManager = artifacts.require("MatchManager");

contract("MatchManager", accounts => {
    const [firstAccount, secondAccount, thirdAccount] = accounts;
    let mm;

    const index = {
        matchId:0,
        poolPrice: 1,
        radiantBets:2,
        direBets:3,
        radiantWin:4,
        direWin:5,
        withdrawable: 6,
        bettable:7,
        refundable:8,
    };

    beforeEach(async () => {
        // for testing purposes
        mm = await MatchManager.new();
    });

    it("sets an owner", async () => {
        assert.equal(await mm.owner.call(), firstAccount);
    })
    
    it("check is address that deployed is admin", async() => {
        assert.equal(await mm.addressIsAdmin.call(firstAccount), true);
    })

    it("new address are not admin", async() => {
        assert.equal(await mm.addressIsAdmin.call(secondAccount), false);
    })

    it("allows an admin to change the roles of others", async() => {
        await mm.changeRole(secondAccount , { from: firstAccount })
        assert.equal(await mm.addressIsAdmin.call(secondAccount), true);
    })

    it("can add match if user is an admin", async() => {
        await mm.addMatch(1, { from:firstAccount });
        const addedMatch = await mm.matches.call(0);
        assert.equal(await mm.matchesNumber.call(), 1);
        assert.equal(addedMatch[index.matchId], 1);
        assert.equal(addedMatch[index.bettable], true);
        assert.equal(addedMatch[index.refundable], true);
    })

    it("cant add match if user isnt an admin", async() => {
        try {
            await mm.addMatch(1, 2, { from:secondAccount });
        } catch (err) {
            const length = await mm.matchesNumber.call();
            assert.equal(length.toNumber(), 0);
        }
    })

    it("can start the match, the bets will not refundable and cant bet anymore", async() => {
        await mm.addMatch(1, { from:firstAccount });
        await mm.startMatch(1, { from:firstAccount });
        const addedMatch = await mm.matches.call(0);
        assert.equal(addedMatch[index.refundable], false);
        assert.equal(addedMatch[index.bettable], false);
    })

    it("can end the match, the bets will withdrawable", async() => {
        await mm.addMatch(1, { from:firstAccount });
        await mm.startMatch(1, { from:firstAccount });
        await mm.endMatch(1, { from:firstAccount });
        const addedMatch1 = await mm.matches.call(0);
        assert.equal(addedMatch1[index.withdrawable], true);
        assert.equal(addedMatch1[index.radiantWin], false);     
    })
});