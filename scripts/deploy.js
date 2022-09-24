async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with the account:", deployer.address);

    console.log("Account balance:", (await deployer.getBalance()).toString());

    const RepuSwapFactory = await ethers.getContractFactory("RepuSwapFactory");
    const repuSwapFactory = await RepuSwapFactory.deploy();

    console.log("RepuSwapFactory address:", repuSwapFactory.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });