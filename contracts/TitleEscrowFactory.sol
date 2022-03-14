// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./TitleEscrowCloneable.sol";
import "./interfaces/ITitleEscrowFactory.sol";

contract TitleEscrowFactory is ITitleEscrowFactory {
  address public override implementation;

  constructor() {
    implementation = address(new TitleEscrowCloneable());
  }

  function create(
    address beneficiary,
    address holder,
    uint256 tokenId
  ) external override returns (address) {
    bytes32 salt = keccak256(abi.encodePacked(msg.sender, tokenId));
    address titleEscrow = Clones.cloneDeterministic(implementation, salt);
    TitleEscrowCloneable(titleEscrow).initialize(msg.sender, beneficiary, holder, tokenId);

    // TODO: Add tokenId to event
    emit TitleEscrowDeployed(titleEscrow, msg.sender, beneficiary, holder);

    return titleEscrow;
  }

  function getAddress(address tokenRegistry, uint256 tokenId) external pure override returns (address) {
    return Clones.predictDeterministicAddress(implementation, keccak256(abi.encodePacked(tokenRegistry, tokenId)));
  }
}
