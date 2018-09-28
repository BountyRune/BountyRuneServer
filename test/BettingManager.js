const BettingManager = artifacts.require("BettingManager");

contract("BettingManager", accounts => {
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
        bm = await BettingManager.new();
    });

    it("It can bet while the game is not started and return correct value", async() => {
        try {
            await bm.addMatch(1, { from:firstAccount });
            await bm.bet(1, true, {from: secondAccount, value: web3.toWei('0.05')})
            await bm.bet(1, false, {from: thirdAccount, value: web3.toWei('0.1')})
            const addedMatch = await bm.matches.call(0);
            assert.equal(addedMatch[index.radiantBets], web3.toWei('0.05'));
            assert.equal(addedMatch[index.direBets], web3.toWei('0.1'));
        } catch (err) {
            const length = await bm.matchesNumber.call();
            assert.equal(length.toNumber(), 0);
        }
    })
});