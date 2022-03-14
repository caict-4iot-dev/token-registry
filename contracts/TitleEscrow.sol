// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ITitleEscrow.sol";
import "./interfaces/ITradeTrustERC721.sol";

contract TitleEscrow is ITitleEscrow, Initializable, Context {
  address public beneficiary;
  address public holder;

  address public nominatedBeneficiary;
  address public nominatedHolder;

  address public tokenRegistry;
  uint256 public tokenId;
  //  ITitleEscrow.StatusTypes public override status;

  modifier onlyBeneficiary() {
    require(_msgSender() == beneficiary, "TitleEscrow: Caller is not beneficiary");
    _;
  }

  modifier onlyHolder() {
    require(_msgSender() == holder, "TitleEscrow: Caller is not holder");
    _;
  }

  modifier whenHoldingToken() {
    require(_isHoldingToken(), "TitleEscrow: Not holding token");
    _;
  }

  modifier whenNotPaused() {
    bool paused = Pausable(address(tokenRegistry)).paused();
    require(!paused, "TitleEscrow: Token Registry is paused");
    _;
  }

  function initialize(
    address _tokenRegistry,
    address _beneficiary,
    address _holder,
    uint256 _tokenId
  ) public initializer {
    tokenRegistry = _tokenRegistry;
    beneficiary = _beneficiary;
    holder = _holder;
    tokenId = _tokenId;
  }

  function onERC721Received(
    address, /* operator */
    address from,
    uint256 _tokenId,
    bytes calldata /* data */
  ) external override returns (bytes4) {
    require(tokenId == _tokenId, "TitleEscrow: Unable to accept token");
    require(
      _msgSender() == address(tokenRegistry),
      "TitleEscrow: Only tokens from predefined token registry can be accepted"
    );

    emit TokenReceived(tokenRegistry, from, _tokenId);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function nominateBeneficiary(address _nominatedBeneficiary) external onlyBeneficiary whenHoldingToken whenNotPaused {
    nominatedBeneficiary = _nominatedBeneficiary;
  }

  function nominateHolder(address _nominatedHolder) external onlyBeneficiary whenHoldingToken whenNotPaused {
    nominatedHolder = _nominatedHolder;
  }

  function nominate(address _nominatedBeneficiary, address _nominatedHolder)
    external
    onlyBeneficiary
    whenHoldingToken
    whenNotPaused
  {
    nominatedBeneficiary = _nominatedBeneficiary;
    nominatedHolder = _nominatedHolder;
  }

  function endorseBeneficiary(address _nominatedBeneficiary) external onlyHolder whenHoldingToken whenNotPaused {
    require(_nominatedBeneficiary != address(0), "TitleEscrow: Cannot endorse address");
    require(
      beneficiary == holder || (nominatedBeneficiary == _nominatedBeneficiary),
      "TitleEscrow: Cannot endorse non-nominees"
    );
    nominatedBeneficiary = address(0);
    beneficiary = _nominatedBeneficiary;
  }

  function endorseHolder(address _nominatedHolder) external onlyHolder whenHoldingToken whenNotPaused {
    if (_nominatedHolder != address(0)) {
      require(
        beneficiary == holder || (nominatedHolder == _nominatedHolder),
        "TitleEscrow: Cannot endorse non-nominees"
      );
    }
    nominatedHolder = address(0);
    holder = _nominatedHolder;
  }

  function endorse(address _nominatedBeneficiary, address _nominatedHolder)
    external
    onlyHolder
    whenHoldingToken
    whenNotPaused
  {
    require(
      _nominatedBeneficiary != address(0) && _nominatedHolder != address(0),
      "TitleEscrow: Cannot endorse addresses"
    );
    require(
      beneficiary == holder || (nominatedBeneficiary == _nominatedBeneficiary && nominatedHolder == _nominatedHolder),
      "TitleEscrow: Cannot endorse non-nominees"
    );

    _resetNominees();
    beneficiary = nominatedBeneficiary;
    holder = nominatedHolder;
  }

  function surrender() external onlyBeneficiary onlyHolder whenHoldingToken whenNotPaused {
    _resetNominees();
    ITradeTrustERC721(tokenRegistry).safeTransferFrom(address(this), tokenRegistry, tokenId);
  }

  function shred() external whenNotPaused {
    require(!_isHoldingToken(), "TitleEscrow: Not surrendered yet");
    require(_msgSender() == tokenRegistry, "TitleEscrow: Caller is not registry");
    selfdestruct(payable(tx.origin));
  }

  function isHoldingToken() external view returns (bool) {
    return _isHoldingToken();
  }

  function _isHoldingToken() internal view returns (bool) {
    return ITradeTrustERC721(tokenRegistry).ownerOf(tokenId) == address(this);
  }

  function _resetNominees() internal {
    nominatedBeneficiary = address(0);
    nominatedHolder = address(0);
  }
}
