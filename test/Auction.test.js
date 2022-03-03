const { assert } = require("chai");
const { ethers } = require("hardhat");

let Dauction, dauction, NFTContract, nftContract, nftContractAddress, auctionContractAddress, deployer, addr1, addr2
describe("Dauction Marketplace", async () =>  {

  beforeEach(async () => {

    NFTContract = await ethers.getContractFactory('NFTContract');
    // console.log(nftContract)
    nftContract = await NFTContract.deploy('AuctionNFT', 'ANFT');
    await nftContract.deployed();
    nftContractAddress = nftContract.address;
    
    
    Dauction = await ethers.getContractFactory('Dauction');
    dauction = await Dauction.deploy(nftContractAddress);
    await dauction.deployed();
    auctionContractAddress = dauction.address;

    [deployer, addr1, addr2] = await ethers.getSigners()


    const firstMintTxn = await nftContract.connect(deployer).mint(deployer.address, 1)
    await firstMintTxn.wait()

    console.log(`NFT deployed to : ${nftContractAddress}`)
    console.log(`Dauction Marketplace deployed to : ${auctionContractAddress}`)
    
    

    // deployer = deployer.address
    // addr1 = addr1.address
  })

  describe('Deployment', () => {
    it("Should return dauction contract address and NFT contract address", async () =>  {
      console.log(`NFT deployeded to : ${nftContractAddress}`)
      console.log(`Dauction Marketplace deployeded to : ${auctionContractAddress}`)
    });
  })

  describe('Mint NFt', () => {
    it("Should allow deployer to mint NFT", async () =>  {
      const NFTOwner = await nftContract.ownerOf(1)
      assert.equal(deployer.address, NFTOwner)
      console.log(`deployer here: ${deployer.address}`)
      
    });
  })

  describe('Create Dauction', () => {
    it("Should allow deployer to create dauction", async () =>  {
      const deployerApproveNFTTxn = await nftContract.connect(deployer).approve(auctionContractAddress, 1)
      await deployerApproveNFTTxn.wait()

      const approvedAccount = await nftContract.getApproved(1)
      console.log(`approved account: ${approvedAccount}`)

      console.log(`dauction contract address here: ${dauction.address}`)

      const createAuctionTxn = await dauction.connect(deployer).createAuction(1, 5)
      await createAuctionTxn.wait()     

      const auctionDetails = await dauction.auctions(nftContractAddress, 1)
      const { seller, startDate, minBid, endDate, highestBidAddress, highestBidAmount } = auctionDetails


      console.log(`seller: ${seller}`)
      console.log(`start date: ${startDate}`)
      console.log(`minbid: ${minBid}`)
      console.log(`endDate: ${endDate}`)
      console.log(`highest bid address: ${highestBidAddress}`)
      console.log(`highest bid amount: ${highestBidAmount}`)

      assert.equal(seller, deployer.address)
      assert.equal(minBid, 5)
    });
  })

});


