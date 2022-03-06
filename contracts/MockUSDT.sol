// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract MockUSDT is Ownable, ERC20  {
  address deployer;
  constructor() ERC20('MockUSDT', 'MUSDT') {
    _mint(msg.sender, 200000000 * 10 ** 18);
    deployer = msg.sender;
  }
}