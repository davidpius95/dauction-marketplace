const { assert } = require("chai");
const { ethers } = require("hardhat");

const { parseToken, formatToken } = require('../utility/conversion.utils')

let Dauction, 
    dauction, 
    NFTContract, 
    nftContract, 
    nftContractAddress, 
    auctionContractAddress, 
    MockUSDT, 
    mockUSDT,
    usdtContractAddress, 
    deployer, 
    addr1, 
    addr2, 
    addr3, 
    addr4, 
    addr5, 
    addr6, 
    addr7,
    addr8
describe("Dauction Marketplace", async () =>  {

  beforeEach(async () => {
    [deployer, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8] = await ethers.getSigners();
    NFTContract = await ethers.getContractFactory('NFTContract');
    nftContract = await NFTContract.deploy('AuctionNFT', 'ANFT');
    await nftContract.deployed();
    nftContractAddress = nftContract.address;


    MockUSDT = await ethers.getContractFactory('MockUSDT')
    mockUSDT = await MockUSDT.deploy()
    await mockUSDT.deployed()
    usdtContractAddress = mockUSDT.address;
    
    
    Dauction = await ethers.getContractFactory('Dauction');
    dauction = await Dauction.deploy(nftContractAddress, usdtContractAddress);
    await dauction.deployed();
    auctionContractAddress = dauction.address;


    const transferUSDTToAddr1 = await mockUSDT.connect(deployer).transfer(addr1.address, parseToken(10000000));
    await transferUSDTToAddr1.wait();

  





    const firstMintTxn = await nftContract.connect(deployer).mint(deployer.address, 1)
    await firstMintTxn.wait()

    console.log(`NFT deployed to : ${nftContractAddress}`)
    console.log(`Dauction Marketplace deployed to : ${auctionContractAddress}`)
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

      let userSpecifiedTime = Math.floor(Date.now() / 1000) + (0.05 * 60)

      console.log(`user specified time: ${userSpecifiedTime}`)

      // (Date.now() / 1000) - (5 * 60)

      const createAuctionTxn = await dauction.connect(deployer).createAuction(1, 5, userSpecifiedTime)
      await createAuctionTxn.wait()     

      const auctionDetails = await dauction.auctions(nftContractAddress, 1)
      const { seller, startDate, minBidPrice, endDate, highestBidAddress, highestBidAmount, auctionStatus } = auctionDetails

      const auctionState = await dauction.getAuctionStatus(nftContractAddress, 1)

      console.log(`auction status: ${auctionState}`)

      console.log(`seller: ${seller}`)
      console.log(`start date: ${startDate}`)
      console.log(`minbid: ${minBidPrice}`)
      console.log(`endDate: ${endDate}`)
      console.log(`highest bid address: ${highestBidAddress}`)
      console.log(`highest bid amount: ${highestBidAmount}`)
      console.log(`auction status: ${auctionStatus}`)

      assert.equal(seller, deployer.address)
      assert.equal(minBidPrice, 5)
      assert.equal(auctionStatus, 1)
      assert.equal(auctionState, auctionState)


      const createBidTxn = await dauction.connect(addr1).createBid(1, 6)
      await createBidTxn.wait()

      const addr1BidStatus = await dauction.getBidStatus(nftContractAddress, 1)
      const getBidder1 = await dauction.getBidder(nftContractAddress, 1)

      console.log(`address 1 bid status txn: ${addr1BidStatus}`)
      console.log(`address 1 bid status txn: ${getBidder1}`)

      
    });
  })

});


