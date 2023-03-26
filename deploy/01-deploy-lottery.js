const { network, ethers } = require("hardhat")
const { developmentChains, networkConfig } = require("../helper-hardhat-config")

const VRF_SUB_FUND_AMOUNT = ethers.utils.parseEther("10")

module.exports = async function ({getNamedAccounts, deployments}) {
    const {deploy , logs} = deployments
    const {deployer} = await getNamedAccounts()
    const chainId = network.config.chainId
    let vrfCoordinatorV2Address, subscriptionId

    if(developmentChains.includes(network.name)) {
        const vrfCoordinatorV2Mock = await ethers.getContract("VRFCoordinatorV2Mock")
        vrfCoordinatorV2Address = vrfCoordinatorV2Mock.address
        const transactionResponce = await vrfCoordinatorV2Mock.createSubscription()
        const transactionReceipt = await transactionResponce.wait(1)
        subscriptionId =transactionReceipt.events[0].args.subId
        // fund subscruptuin, you need to fund Link
        await vrfCoordinatorV2Address.fundSubscription(subscriptionId, VRF_SUB_FUND_AMOUNT )
    }else{          
        vrfCoordinatorV2Address = networkConfig[chainId]["vrfCoordinatorV2"]
        subscriptionId = networkConfig[chainId]["subscriptionId"]
    }

    const entranceFee = networkConfig[chainId]["entranceFee"]
    const gasLane = networkConfig[chainId]["gasLane"]
    const callbackGasLimit = networkConfig[chainId]["callbackgasLimit"]
    const interval = networkConfig[chainId]["interval"]

    const args =[vrfCoordinatorV2Address, entranceFee, gasLane, subscriptionId, callbackGasLimit, interval]
    const raffle = await deploy("Raffle", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1 ,
    })
}