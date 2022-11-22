const { expect } = require("chai");
const {ethers} = require("hardhat");
const {loadFixture} = require("@nomicfoundation/hardhat-network-helpers");

describe("Pick contract", function () {

    async function deployPickFixture() {

        const [owner, addr1] = await ethers.getSigners();

        const Pick = await ethers.getContractFactory("Pick");
        let pick = await Pick.deploy();
        await pick.deployed();

        return {pick, owner, addr1};
    }

    describe('pick relevant', function () {

        it('should set the right contract owner', async function () {
            const {pick, owner} = await loadFixture(deployPickFixture);

            expect(await pick.owner()).to.equal(owner.address);
        });

        it('setMinter', async function () {
            const {pick, addr1} = await loadFixture(deployPickFixture);

            await pick.setMinter(addr1.address);

            expect(await pick.minter()).to.equal(addr1.address);
        });

        it('pause', async function () {
            const {pick} = await loadFixture(deployPickFixture);

            await pick.pause();

            expect(await pick.paused()).to.be.true;

        });

        it('unpause', async function () {
            const {pick} = await loadFixture(deployPickFixture);

            await pick.pause();

            await pick.unpause();

            expect(await pick.paused()).to.be.false;

        });

        it('mintTo', async function () {
            const {pick, owner} =await loadFixture(deployPickFixture);

            await pick.mintTo(owner.address, 10);

            expect(await pick.balanceOf(owner.address)).to.equal(10);
        });

    });
});