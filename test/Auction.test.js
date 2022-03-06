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
    // get signers
    [deployer, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8] = await ethers.getSigners();

    // nft contract deployment
    NFTContract = await ethers.getContractFactory('NFTContract');
    nftContract = await NFTContract.deploy('AuctionNFT', 'ANFT');
    await nftContract.deployed();
    nftContractAddress = nftContract.address;

    // mockUSDT contract deployment
    MockUSDT = await ethers.getContractFactory('MockUSDT')
    mockUSDT = await MockUSDT.deploy()
    await mockUSDT.deployed()
    usdtContractAddress = mockUSDT.address;
    
    // dauction marketplace contract deployment
    Dauction = await ethers.getContractFactory('Dauction');
    dauction = await Dauction.deploy(nftContractAddress, usdtContractAddress);
    await dauction.deployed();
    auctionContractAddress = dauction.address;

    // transaction: transfer 1m mockUSDT to addr1
    const transferUSDTToAddr1 = await mockUSDT.connect(deployer).transfer(addr1.address, parseToken(10000000));
    await transferUSDTToAddr1.wait();

    // first 10 nft mint by deployer
    const totalMints = 10;
    for(i = 0; i < totalMints; i++) {
      const txn = await nftContract.connect(deployer).mintNFT()
      await txn.wait()
    }
  })

  describe('Deployment', () => {
    it("Should return dauction contract address and NFT contract address", async () =>  {
      console.log(`NFT contract address: ${nftContractAddress}`)
      console.log(`Dauction Marketplace contract address: ${auctionContractAddress}`)
    })
  })

  describe('Mint NFt', () => {
    it("Checks nft mint status following successful deployment", async () =>  {
      // check owner of nft 1
      const NFT1Owner = await nftContract.ownerOf(1)
      assert.equal(NFT1Owner, deployer.address)

      // check owner of nft 2
      const NFT2Owner = await nftContract.ownerOf(2)
      assert.equal(NFT2Owner, deployer.address)

      // check total NFT minted
      const totalNFTMinted = await nftContract.totalMinted()
      assert.equal(totalNFTMinted, 10)
    })
  })

  describe('Create Dauction', () => {
    it("Should allow deployer to create dauction", async () =>  {
      // deployer/seller approves auction contract
      const deployerApproveNFTTxn = await nftContract.connect(deployer).approve(auctionContractAddress, 1)
      await deployerApproveNFTTxn.wait()

      // check nft 1 approval status
      const approvedAccount = await nftContract.getApproved(1)
      console.log(`approved account: ${approvedAccount}`)
      console.log(`dauction contract address: ${dauction.address}`)

      // 5 mins
      let userSpecifiedTime = Math.floor(Date.now() / 1000) + (5 * 60)
      console.log(`user specified time: ${userSpecifiedTime}`)

      // deployer/seller creates auction
      const createAuctionTxn = await dauction.connect(deployer).createAuction(1, 5, userSpecifiedTime)
      await createAuctionTxn.wait()     


      // get auction details
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
      
      // addr1 initiates bid 1
      const createBidTxn = await dauction.connect(addr1).createBid(1, 6)
      await createBidTxn.wait()
      
      // get addr1 bid status
      const addr1BidStatus = await dauction.getBidStatus(nftContractAddress, 1)
      const bidder1 = await dauction.getBidder(nftContractAddress, 1)

      // get addr1 bid hash
      const getBidHash = await dauction.getBidHash(nftContractAddress, 1)
      console.log(`bid hash: ${getBidHash}`)
      

      console.log(`address 1 bid status txn: ${addr1BidStatus}`)
      console.log(`bidder 1: ${bidder1}`)
      
      assert.equal(addr1BidStatus, 'Initiated')
      assert.equal(bidder1, addr1.address)

     
      
    })
  })

});


