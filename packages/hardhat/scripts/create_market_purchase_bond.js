
const main = async () => {
    // note that bondable and Token contracts were deployed previously (with hardhat-deploy)
    const { deployer } = await getNamedAccounts();
    console.log('deployer', deployer.address);
    let bondableContract = await ethers.getContract("Bondable", deployer);
    let underlyingContract = await ethers.getContract("Token", deployer);

    //const provider = new ethers.providers.JsonRpcProvider($rpcUrl);
    //const bondableFactory = new ethers.ContractFactory(bondableContract.abi, bondableContract.evm.bytecode, provider.getSigner());
    //const underlyingFactory = new ethers.ContractFactory(underlyingContract.abi, underlyingContract.evm.bytecode, provider.getSigner());

    console.log('Approving bondable contract');
    await underlyingContract.approve(bondableContract.address, '9999999999999999999999999999999999999999');


    console.log("Calling createMarket function");
    await bondableContract.createMarket(underlyingContract.address,
        '1672547973',
        '100000000000000000000000', // $100,000 in 1e18 base decimals
        '95000000000000000000', // $0.95 per bond in 1e18 base decimals, ~5.25% APY
        '0xKernel-5.25%-1672547971',
        '0xKernel-Dec-22-Debt',
        'KERN-DEC'
    );


    console.log('Purchasing a bond');
    await bondableContract.mint(underlyingContract.address,
        '1672547973',
        '1');

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

