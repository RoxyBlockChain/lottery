const { ethers } = require("hardhat")
const { updateArrayBindingPattern } = require("typescript")
const {fs} = require("fs")

const FRONT_END_ADDRESSES_FILE = "../nextjs_lottery/constants/contractAddresses.json"
const FRONT_END_ABI_FILE = "../nextjs_lottery/constants/abi.json"

module.exports = async function(){
    if(process.env.UPDATE_FRONT_END){
        console.log(" Updating Front end from Backend")
        updateContractAddress()
        updateAbi()
}
}

async function updateAbi(){

    const raffle = await ethers.getContract("Raffle")
    fs.writeFileSync(FRONT_END_ABI_FILE, raffle.interface.format(ethers.utils.FormatTypes.JSON))
}       

async function updateContractAddress(){
    const raffle = await ethers.getContract("Raffle")
    const chainId = network.config.chainId.toString()
    const currentAddresses = JSON.parse(fs.readFileSync(FRONT_END_ADDRESSES_FILE, "utf8"))
    if (chainId in currentAddresses){
        if(!currentAddresses[chainId].include(raffle.address)){
            currentAddresses[chainId].push(raffle.address)
        }
    } { 
        currentAddresses[chainId] = [raffle.address]
    }
    fs.writeFileSync(FRONT_END_ADDRESSES_FILE, JSON.stringify(currentAddresses))
}

module.exports.tags =[ "all", "frontend"]