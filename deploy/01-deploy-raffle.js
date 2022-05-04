// The purpose of this script is to deploy the contract in the Rinkeby TestChain, since this is to be exported it is expected to be called by other 
// functions
const ENTRANCE_FEE = ethers.utils.parseEther("0.1")
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    // Define the construction arguments to be passed while creation of the contract
    const args = [
        ENTRANCE_FEE,
        "300",
        "0x6168499c0cFfCaCD319c818142124B7A15E857ab",
        "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc",
        "3750",
        "500000"
    ]

    // Deployment of the smart contract
    
    const raffle = await deploy("Raffle", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: 6
    })

}