const { assert } = require("chai");
const { network, deployments, ethers } = require("hardhat");
const { describe, it } = require("node:test");
const {developmentChains, networkConfig} = require("../../helper-hardhat-config");

!developmentChains.includes(network.name) 
? describe.skip 
: describe("Raffle Unit Tests" , async function (){
    let raffle, vrfCoordinatorV2Mock, interval;
    beforeEach (async function(){
        const {deployer} = await getNamedAccounts()
        await deployments.fixture(["all"])
        raffle = await ethers.getContract("Raffle", deployer)
        vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock", deployer)
        interval = await raffle.getInterval()
    })
    describe("Constractor", async function(){
        it("Initialized the Raffle Correctly", async function (){
            // ideally we make our tests have 1 assert per it
            const raffleState = await raffle.getRaffleState()
            const interval = await raffle.getInterval()
            assert.equal(raffleState.toString(), "0")  // .toString is to stingify the Big Number
            assert.equal(interval.toString(), networkConfig[network.config.chainId]["keepersUpdateInterval"])
        })
    })
})