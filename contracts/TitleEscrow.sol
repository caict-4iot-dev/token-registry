// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./interfaces/ITitleEscrow.sol";
import "./interfaces/ITradeTrustERC721.sol";

contract TitleEscrow is ITitleEscrow, Initializable {
  address public override tokenRegistry;
  uint256 public override tokenId;

  address public override beneficiary;
  address public override holder;

  address public override nominatedBeneficiary;
  address public override nominatedHolder;

  modifier onlyBeneficiary() {
    require(msg.sender == beneficiary, "TitleEscrow: Caller is not beneficiary");
    _;
  }

  modifier onlyHolder() {
    require(msg.sender == holder, "TitleEscrow: Caller is not holder");
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
    address, /* from */
    uint256 _tokenId,
    bytes calldata /* data */
  ) external override returns (bytes4) {
    require(tokenId == _tokenId, "TitleEscrow: Unable to accept token");
    require(
      msg.sender == address(tokenRegistry),
      "TitleEscrow: Only tokens from predefined token registry can be accepted"
    );

    emit TokenReceived(tokenRegistry, _tokenId);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function nominateBeneficiary(address _nominatedBeneficiary)
    external
    override
    whenNotPaused
    onlyBeneficiary
    whenHoldingToken
  {
    nominatedBeneficiary = _nominatedBeneficiary;

    emit BeneficiaryNomination(tokenRegistry, tokenId, nominatedBeneficiary, msg.sender);
  }

  function nominateHolder(address _nominatedHolder) external override whenNotPaused onlyBeneficiary whenHoldingToken {
    nominatedHolder = _nominatedHolder;

    emit HolderNomination(tokenRegistry, tokenId, nominatedHolder, msg.sender);
  }

  function nominate(address _nominatedBeneficiary, address _nominatedHolder)
    external
    override
    whenNotPaused
    onlyBeneficiary
    whenHoldingToken
  {
    nominatedBeneficiary = _nominatedBeneficiary;
    nominatedHolder = _nominatedHolder;

    emit BeneficiaryNomination(tokenRegistry, tokenId, nominatedBeneficiary, msg.sender);
    emit HolderNomination(tokenRegistry, tokenId, nominatedHolder, msg.sender);
  }

  function endorseBeneficiary(address _nominatedBeneficiary)
    external
    override
    whenNotPaused
    onlyHolder
    whenHoldingToken
  {
    require(_nominatedBeneficiary != address(0), "TitleEscrow: Cannot endorse address");
    require(
      beneficiary == holder || (nominatedBeneficiary == _nominatedBeneficiary),
      "TitleEscrow: Cannot endorse non-nominees"
    );
    nominatedBeneficiary = address(0);
    beneficiary = _nominatedBeneficiary;

    emit BeneficiaryEndorsement(tokenRegistry, tokenId, beneficiary, msg.sender);
  }

  function endorseHolder(address _nominatedHolder) external override whenNotPaused onlyHolder whenHoldingToken {
    if (_nominatedHolder != address(0)) {
      require(
        beneficiary == holder || (nominatedHolder == _nominatedHolder),
        "TitleEscrow: Cannot endorse non-nominees"
      );
    }
    nominatedHolder = address(0);
    holder = _nominatedHolder;

    emit HolderEndorsement(tokenRegistry, tokenId, holder, msg.sender);
  }

  function endorse(address _nominatedBeneficiary, address _nominatedHolder)
    external
    override
    whenNotPaused
    onlyHolder
    whenHoldingToken
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

    emit BeneficiaryEndorsement(tokenRegistry, tokenId, beneficiary, msg.sender);
    emit HolderEndorsement(tokenRegistry, tokenId, holder, msg.sender);
  }

  function surrender() external override onlyBeneficiary onlyHolder whenNotPaused whenHoldingToken {
    _resetNominees();
    ITradeTrustERC721(tokenRegistry).safeTransferFrom(address(this), tokenRegistry, tokenId);

    emit Surrender(tokenRegistry, tokenId, beneficiary, holder);
  }

  function shred() external override whenNotPaused {
    require(!_isHoldingToken(), "TitleEscrow: Not surrendered yet");
    require(msg.sender == tokenRegistry, "TitleEscrow: Caller is not registry");
    selfdestruct(payable(tx.origin));

    emit Shred(tokenRegistry, tokenId);
  }

  function isHoldingToken() external view override returns (bool) {
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
