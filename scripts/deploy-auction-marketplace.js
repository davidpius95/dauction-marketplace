const hre = require("hardhat");

const main = async () => {
  const NFTContract = await hre.ethers.getContractFactory('NFTContract')
  const nftContract = await NFTContract.deploy()
  await nftContract.deployed()
  const nftContractAddress = nftContract.address
  console.log(`NFT Contract address: ${nftContractAddress}`)
  
  const Dauction = await hre.ethers.getContractFactory('Dauction')
  const dauction = await Dauction.deploy(nftContractAddress)
  await dauction.deployed()
  const dauctionAddress = dauction.address
  console.log(`Auction Marketplace deployeded to : ${dauctionAddress}`)
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(`deploy error: ${err}`);
    process.exit(1);
  });
