//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import './VRFv2Consumer.sol';

contract Dauction is ReentrancyGuard {
  IERC721 iERC721;
  IERC721 iUSDT;

  address  public nftContractAddress;
 
  uint256 public activeAuctions;
  uint256 public totalExecutedAuctions;

  enum BidStatus {
    Unassigned, 
    Initiated,
    Executed
  }
  struct Bid {
    address bidder;
    uint256 bidId;
    uint256 amountBidded;
    bytes32 bidHash;
    uint256 biddedAt;
    BidStatus bidStatus;
  }
  
  uint256[] bidArray;
  uint256 bidCount;
  uint256 constant minUSDTBidAmount = 20;
  bytes32 hashedBid;

  uint8 private nonce = 0;
  
   enum AuctionStatus { 
    Unassigned, 
    Initiated,
    Bidded,
    Executed,
    Unexecuted
  }
  struct Auction {
    address payable seller;
    uint startDate;
    uint minBidPrice;
    uint endDate;
    address payable highestBidAddress;
    uint highestBidAmount;
    AuctionStatus auctionStatus;
    mapping(uint256 => Bid) bids;
  }

  mapping(address => mapping(uint => Auction)) public auctions;

  event AuctionCreated(
    uint256 tokenId,
    uint256 sellerSpecifiedTime,
    address seller,
    uint256 minBidPrice,
    uint256 startDate,
    uint256 endDate
  );

  constructor (address _NFTContractAddress, address _usdtContractAddress){
    iERC721 = IERC721(_NFTContractAddress);
    nftContractAddress = _NFTContractAddress; 
    iUSDT = IERC721(_usdtContractAddress);
  }

  function createAuction(uint256 _tokenId, uint _minBidPrice, uint256 userSpecifiedTime) public nonReentrant {
    require(_minBidPrice > 0, 'bid price cannot be zero');
    require(msg.sender == iERC721.ownerOf(_tokenId), 'not owner');
    
    //require(msg.value >= listingFee, "pay the listing fees");
    Auction storage auction = auctions[nftContractAddress][_tokenId];
    require(auction.endDate == 0, "auction already exist"); 
    iERC721.transferFrom(msg.sender, address(this), _tokenId);
   
    auction.seller = payable(msg.sender); 
    auction.minBidPrice = _minBidPrice; 
    auction.auctionStatus = AuctionStatus.Initiated;
    auction.startDate = block.timestamp;
    auction.endDate = block.timestamp + userSpecifiedTime; 
    auction.highestBidAddress = payable(address(0));
    auction.highestBidAmount = 0;
    activeAuctions += 1;

    emit AuctionCreated({
      tokenId: _tokenId,
      seller: msg.sender,
      sellerSpecifiedTime: userSpecifiedTime,
      minBidPrice: _minBidPrice, 
      startDate: auction.startDate,
      endDate: auction.endDate
    });
  }


  function createBid(uint _tokenId, uint256 _usdtBidAmount) external {
    require(iUSDT.balanceOf(msg.sender) >= minUSDTBidAmount, 'low USDT bal');
    
    Auction storage auction = auctions[nftContractAddress][_tokenId];
    require(msg.sender != auction.seller, 'seller cannot bid');
    require(_usdtBidAmount >= auction.minBidPrice, 'bid cannot be lower than min amount specified');
    
    require(auction.endDate != 0, "auction does not exist");
    require(auction.endDate >= block.timestamp, "auction is finished");
    // require(
    //   auction.highestBidAmount < msg.value && auction.minBidPrice < msg.value, 
    //   "bid amount is too low"
    // );
    bidCount += 1;
    // bids[bidCount][msg.sender].amountBidded = _usdtBidAmount ;
    uint8 randomIndex = getRandomIndex(msg.sender);

    bytes32 hashedBidAmount = hashBidAmount(msg.sender, _usdtBidAmount, randomIndex);

    auction.bids[bidCount].bidHash = hashedBidAmount;
    auction.bids[bidCount].bidder = msg.sender;
    auction.bids[bidCount].bidId = bidCount;

    auction.bids[bidCount].bidStatus = BidStatus.Initiated; 


    if(block.timestamp >= auction.endDate) {
      _decodehashedBidAmount(hashedBidAmount, _usdtBidAmount);
    }
  }

  function hashBidAmount(address account, uint256 amount, uint8 randomNum) public returns(bytes32) {
    hashedBid = keccak256(abi.encodePacked(account, amount, randomNum));
    return hashedBid;
  }

  function getRandomIndex(address _account) internal returns(uint8) {
    uint8 maxValue = 10;
    uint8 random  = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), _account))) % maxValue);
    if(nonce > 250) {
      nonce = 0;
    }
    console.log('generated random no: %s', random);
    return random;
  }

  function _decodehashedBidAmount(bytes32 _hashedBid, uint256 _auctionEntryAmount) private returns(uint256) {
    // 1. check if passed in value returns true when compared with keccak256 hash function
    require(keccak256(abi.encodePacked(_hashedBid)) == hashedBid, 'not corresponding hash');

    // 2. return and save the uint256 value
    uint256 auctionEntryAmount = _auctionEntryAmount;
    console.log('auction amount: %s', auctionEntryAmount);

    // 3. push the saved value into an array
    bidArray.push(auctionEntryAmount);

    // 4. loop through array 
    for(uint256 i = 0; i < bidArray.length; i++) {
      console.log('iterated i: %s', i);
      return bidArray[i];
    } 

    // 5. return iterated values based on asc. order
  }


  function closeBid(address NFTAddress, uint _tokenId) external {
    Auction storage auction = auctions[NFTAddress][_tokenId];
    require(auction.endDate != 0, "auction does not exist");
    require(auction.endDate < block.timestamp, "auction has not finished");
    if(auction.highestBidAmount == 0) {
      //auction failed, no bidder showed up.
      IERC721(NFTAddress).transferFrom(address(this), auction.seller, _tokenId);
      delete auctions[NFTAddress][_tokenId];
    } else {
      //auction succeeded, send money to seller, and token to buyer
      auction.seller.transfer(auction.highestBidAmount);
      IERC721(NFTAddress).transferFrom(address(this), auction.highestBidAddress, _tokenId);
      delete auctions[NFTAddress][_tokenId];
    }
  }



  /********************************************************************************************/
  /*                                      UTILITY FUNCTIONS                                  */
  /******************************************************************************************/
  function getMinBidPrice(address nftAddress, uint256 tokenId)  public view returns(uint256) {
    return auctions[nftAddress][tokenId].minBidPrice;
  }

  function getAuctionStatus(address nftAddress, uint256 tokenId) public view returns(string memory _auctionStatus) {
    uint8 auctionState = uint8(auctions[nftAddress][tokenId].auctionStatus);
    if(auctionState == 0) {
      _auctionStatus = 'Unassigned';
    } else if(auctionState == 1) {
      _auctionStatus = 'Initiated';
    } else if(auctionState == 2) {
      _auctionStatus = 'Bidded';
    }  else if(auctionState == 3) {
      _auctionStatus = 'Executed';
    }  else if(auctionState == 4) {
      _auctionStatus = 'Unexecuted';
    } 
  }

  // mapping(uint256 => mapping(address => Bid)) public bids;

  function getBidStatus(address nftAddress, uint256 tokenId) public view returns(string memory _auctionStatus) {
    uint8 bidState = uint8(auctions[nftAddress][tokenId].bids[tokenId].bidStatus);
    if(bidState == 0) {
      _auctionStatus = 'Unassigned';
    } else if(bidState == 1) {
      _auctionStatus = 'Initiated';
    } else if(bidState == 2) {
      _auctionStatus = 'Bidded';
    }  else if(bidState == 3) {
      _auctionStatus = 'Executed';
    } 
  }


  function getBidder(address nftAddress, uint256 tokenId) public view returns(address) {
    return auctions[nftAddress][tokenId].bids[tokenId].bidder;
  }


  function getBidHash(address nftAddress, uint256 tokenId) public view returns(bytes32) {
    return auctions[nftAddress][tokenId].bids[tokenId].bidHash;
  }


 
}

