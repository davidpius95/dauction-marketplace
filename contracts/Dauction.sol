//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";




contract Dauction {
  IERC721 iERC721;

  address  public nftAddress;

  struct Auction {
    address payable seller;
    uint startDate;
    uint minBid;
    uint endDate;
    address payable highestBidAddress;
    uint highestBidAmount;
  }


  mapping(address => mapping(uint => Auction)) public auctions;
//uint public listingFe ether;
  event AuctionCreated(
    
    uint tokenId,
    address seller,
    uint minBid,
    uint endDate
  );

  constructor (address _NFTAddress){
    iERC721 = IERC721(_NFTAddress);
    nftAddress = _NFTAddress;
      
  }

  function createAuction(
    uint _tokenId,
    uint _minBid
  ) 
  
  public
  {
    Auction storage auction = auctions[nftAddress][_tokenId];
    
    //require(msg.value >= listingFee, "pay the listing fees");
   // require(auction.endDate == 0, "auction already exist"); 
    console.log('auction end date: %s', auction.endDate);
    console.log(auction.endDate);
   // require(msg.sender == token.ownerOf(_tokenId),"not owner");
    iERC721.transferFrom(msg.sender, address(this), _tokenId);
    console.log('auction end date2: %s', auction.endDate);
    auction.seller = payable(msg.sender); 
    auction.minBid = _minBid; 

    auction.endDate = block.timestamp + 300; 
    console.log('auction end date3: %s', auction.endDate);
    auction.highestBidAddress = payable( address(0));
    auction.highestBidAmount = 0;

    emit AuctionCreated({
      tokenId: _tokenId,
      seller: msg.sender, 
      minBid: _minBid, 
      endDate: block.timestamp + 300
    });
  }

  function createBid( uint _tokenId) external payable {
    Auction storage auction = auctions[nftAddress][_tokenId];
    require(auction.endDate != 0, "auction does not exist");
    require(auction.endDate >= block.timestamp, "auction is finished");
    require(
      auction.highestBidAmount < msg.value && auction.minBid < msg.value, 
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
}