const { expect } = require("chai");

describe("Pick", function () {
    // deploy contract
    async function deploy() {
        // Pick
        const Pick = await hre.ethers.getContractFactory("Pick");
        const pick = await Pick.deploy();
        await pick.deployed();
        return {pick};
    }

    let pick;   
    
    this.beforeAll(async function(){
        const contracts = await deploy();
        pick = contracts.pick;
    } , 10000);

    it("Set Minter" , async function(){
        const [account1 , account2] = await ethers.getSigners();
        await pick.setMinter(account2.address);
        expect(account2.address).to.equal(await pick.minter().then((ret)=>{return ret}));
    });

    it("mintTo" , async function(){
        const [account1 , account2] = await ethers.getSigners();
        await pick.setMinter(account1.address);
        let mintNum = 100;
        await pick.mintTo(account2.address , mintNum);
        expect(await pick.balanceOf(account2.address).then((ret) => {return ret})).to.equal(mintNum);
    });

    it("totalSupply" , async function(){
        expect(await pick.totalSupply()).to.equal(100);
    });
    
    it("transfer" , async function(){
        const [account1 , account2] = await ethers.getSigners();
        await pick.mintTo(account1.address , 100);
        await pick.transfer(account2.address , 10);
        expect(await pick.balanceOf(account1.address).then((ret) => {return ret})).to.equal(90);
    });

    it("approve" , async function(){
        const [account1 , account2] = await ethers.getSigners();
        await pick.approve(account2.address , 100);
        expect(await pick.allowance(account1.address , account2.address).then((ret) => {return ret})).to.equal(100);
    });

    it("decreaseAllowance" , async function(){
        const [account1 , account2] = await ethers.getSigners();
        await pick.decreaseAllowance(account2.address , 100);
        expect(await pick.allowance(account1.address , account2.address).then((ret) => {return ret})).to.equal(0);
    });



});