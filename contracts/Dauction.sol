//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




contract Dauction {
  IERC721 iERC721;

  address  public nftContractAddress;
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
  }

  mapping(address => mapping(uint => Auction)) public auctions;

  event AuctionCreated(
    uint256 tokenId,
    address seller,
    uint256 minBidPrice,
    uint256 startDate,
    uint256 endDate
  );

  constructor (address _NFTAddress){
    iERC721 = IERC721(_NFTAddress);
    nftContractAddress = _NFTAddress;
      
  }

  function createAuction(
    uint _tokenId,
    uint _minBidPrice, 
    uint256 userSpecifiedTime
  ) 
  
  public
  {
    require(msg.sender == iERC721.ownerOf(_tokenId), 'not owner');
    Auction storage auction = auctions[nftContractAddress][_tokenId];
    
    //require(msg.value >= listingFee, "pay the listing fees");
    require(auction.endDate == 0, "auction already exist"); 
    console.log('auction end date: %s', auction.endDate);
    console.log(auction.endDate);
    iERC721.transferFrom(msg.sender, address(this), _tokenId);
   
    console.log('auction end date2: %s', auction.endDate);
    auction.seller = payable(msg.sender); 
    auction.minBidPrice = _minBidPrice; 
    auction.auctionStatus = AuctionStatus.Initiated;
    auction.startDate = block.timestamp;
    auction.endDate = block.timestamp + userSpecifiedTime; 
    console.log('auction end date3: %s', auction.endDate);
    auction.highestBidAddress = payable(address(0));
    auction.highestBidAmount = 0;


    emit AuctionCreated({
      tokenId: _tokenId,
      seller: msg.sender, 
      minBidPrice: _minBidPrice, 
      startDate: auction.startDate,
      endDate: auction.endDate
    });
  }

  function createBid( uint _tokenId) external payable {
    Auction storage auction = auctions[nftContractAddress][_tokenId];
    require(auction.endDate != 0, "auction does not exist");
    require(auction.endDate >= block.timestamp, "auction is finished");
    require(
      auction.highestBidAmount < msg.value && auction.minBidPrice < msg.value, 
      "bid amount is too low"
    );
    //reimburse previous bidder
    auction.highestBidAddress.transfer(auction.highestBidAmount);
    auction.highestBidAddress = payable(msg.sender);
    auction.highestBidAmount = msg.value;
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
}