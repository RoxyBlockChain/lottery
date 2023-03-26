const { network } = require("hardhat")
const {developmentChains} = require("../helper-hardhat-config")

const BASE_FEE = ethers.utils.parseEther("0.25")
const GAS_PRICE_LINK = 1e9 // 10000000000
// this is premium cost 0.25 Link per each request.
// chainlink pay gas to give us Random Number & external computation.


module.exports = async function ({getNamedAccounts, deployments}){
    const {deploy, log} = deployments
    const {deployer} = await getNamedAccounts()
    const chainId = network.config.chainId
    const args = [BASE_FEE, GAS_PRICE_LINK ]


    if(developmentChains.includes(network.name)){
        log("Local Network detected! deploying MOCKS...")
        // we need vrfcoordinatorV2 MOCK contracts.
        await deploy("VRFCoordinatorV2Mock",{
            from: deployer,
            log: true,
            args: args,
        })
        log("Mocks Deployed")
        log("_____________________________________")
    }

}

module.exports.tags = ["all", "mocks"]