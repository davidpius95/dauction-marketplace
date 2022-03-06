   
//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.0 <0.9.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTContract is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _nftIds;

    uint256 public totalMinted;

    constructor(string memory name_, string memory symbol_)
        ERC721(name_, symbol_) {
    }

    function mintNFT() external {
        uint256 newTokenId = _nftIds.current();
        _safeMint(msg.sender, newTokenId);
        _nftIds.increment();
        totalMinted += 1;
    }


    function getTotalMinted() public view returns(uint256) {
        return totalMinted;
    }
}