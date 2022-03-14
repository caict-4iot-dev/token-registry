// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./access/HasNamedBeneficiaryInitializable.sol";
import "./access/HasHolderInitializable.sol";
import "./interfaces/ITitleEscrow.sol";
import "./interfaces/ITradeTrustERC721.sol";
import "./TitleEscrowFactory.sol";

contract TitleEscrow is IERC721Receiver, Initializable, Context {
  address public beneficiary;
  address public holder;

  address public nominatedBeneficiary;
  address public nominatedHolder;

  address public tokenRegistry;
  uint256 public tokenId;
  ITitleEscrow.StatusTypes public override status;

  address public factory;

  constructor() public {
    factory = msg.sender;
  }

  modifier onlyBeneficiary() {
    require(_msgSender() == beneficiary, "TitleEscrow: Caller is not beneficiary");
    _;
  }

  modifier onlyHolder() {
    require(_msgSender() == holder, "TitleEscrow: Caller is not holder");
    _;
  }

  modifier isHoldingToken() {
    require(ITradeTrustERC721(tokenRegistry).ownerOf(tokenId) == address(this), "TitleEscrow: Not holding token");
    _;
  }

  function initialize(
    address _tokenRegistry,
    address _beneficiary,
    address _holder,
    uint256 _tokenId
  ) public initializer {
    require(msg.sender == factory, "TitleEscrow: Not allowed to initialize");
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

    emit TitleReceived(_msgSender(), from, _tokenId);
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function nominateBeneficiary(address _nominatedBeneficiary) external onlyBeneficiary isHoldingToken {
    nominateBeneficiary = _nominatedBeneficiary;
  }

  function nominateHolder(address _nominatedHolder) external onlyBeneficiary isHoldingToken {
    nominateHolder = _nominatedHolder;
  }

  function nominate(address _nominatedBeneficiary, address _nominatedHolder) external onlyBeneficiary isHoldingToken {
    nominateBeneficiary = _nominatedBeneficiary;
    nominateHolder = _nominatedHolder;
  }

  function endorseBeneficiary(address _nominatedBeneficiary) external onlyHolder isHoldingToken {
    require(_nominatedBeneficiary != address(0), "TitleEscrow: Cannot endorse address");
    require(
      beneficiary == holder || (nominatedBeneficiary == _nominatedBeneficiary),
      "TitleEscrow: Cannot endorse non-nominees"
    );
    beneficiary = _nominatedBeneficiary;
    nominateBeneficiary = address(0);
  }

  function endorseHolder(address _nominatedHolder) external onlyHolder isHoldingToken {
    if (_nominatedHolder != address(0)) {
      require(
        beneficiary == holder || (nominatedBeneficiary == _nominatedBeneficiary),
        "TitleEscrow: Cannot endorse non-nominees"
      );
    }
    holder = _nominatedHolder;
    nominateHolder = address(0);
  }

  function endorse(address _nominatedBeneficiary, address _nominatedHolder) external onlyHolder isHoldingToken {
    require(
      _nominatedBeneficiary != address(0) && _nominatedHolder != address(0),
      "TitleEscrow: Cannot endorse addresses"
    );
    require(
      beneficiary == holder || (nominatedBeneficiary == _nominatedBeneficiary && nominatedHolder = _nominatedHolder),
      "TitleEscrow: Cannot endorse non-nominees"
    );

    beneficiary = nominatedBeneficiary;
    holder = nominatedHolder;
    _resetNominees();
  }

  function surrender() external onlyBeneficiary onlyHolder isHoldingToken {
    _resetNominees();
    ITradeTrustERC721(tokenRegistry).safeTransferFrom(address(this), tokenRegistry, tokenId);
  }

  function shred() external {
    require(!_isTokenHolder(), "TitleEscrow: Not surrendered yet");
    require(_msgSender() == tokenRegistry, "TitleEscrow: Caller is not registry");
    selfdestruct(payable(tx.origin));
  }

  function isHoldingToken() external view returns (bool) {
    return _isHoldingToken();
  }

  function _isHoldingToken() view returns (bool) {
    return ITradeTrustERC721(tokenRegistry).ownerOf(tokenId) == address(this);
  }

  function _resetNominees() internal {
    nominateBeneficiary = address(0);
    nominateHolder = address(0);
  }
}

contract TitleEscrowCloneable is
  Context,
  Initializable,
  ITitleEscrow,
  HasHolderInitializable,
  HasNamedBeneficiaryInitializable,
  ERC165
{
  // Documentation on how this smart contract works: https://docs.tradetrust.io/docs/overview/title-transfer

  ITitleEscrow.StatusTypes public override status;

  // Information on token held
  ERC721 public override tokenRegistry;
  uint256 public _tokenId;

  // Factory to clone this title escrow
  ITitleEscrowFactory public titleEscrowFactory;

  // For exiting into title escrow contracts
  address public override approvedBeneficiary;
  address public override approvedHolder;

  function initialize(
    address _tokenRegistry,
    address _beneficiary,
    address _holder,
    address _titleEscrowFactoryAddress
  ) public initializer {
    __initialize__holder(_holder);
    __initialize__beneficiary(_beneficiary);
    tokenRegistry = ERC721(_tokenRegistry);
    titleEscrowFactory = ITitleEscrowFactory(_titleEscrowFactoryAddress);
    status = StatusTypes.Uninitialised;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
    return interfaceId == type(ITitleEscrow).interfaceId;
  }

  function onERC721Received(
    address, /* operator */
    address from,
    uint256 tokenId,
    bytes calldata /* data */
  ) external override returns (bytes4) {
    require(status == StatusTypes.Uninitialised, "TitleEscrow: Contract has been used before");
    require(
      _msgSender() == address(tokenRegistry),
      "TitleEscrow: Only tokens from predefined token registry can be accepted"
    );
    _tokenId = tokenId;
    emit TitleReceived(_msgSender(), from, _tokenId);
    status = StatusTypes.InUse;
    return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
  }

  function changeHolder(address newHolder) public override whenNotPaused isHoldingToken onlyHolder {
    _changeHolder(newHolder);
  }

  modifier allowTransferTitleEscrow(address newBeneficiary, address newHolder) {
    require(newBeneficiary != address(0), "TitleEscrow: Transferring to 0x0 is not allowed");
    require(newHolder != address(0), "TitleEscrow: Transferring to 0x0 is not allowed");
    if (holder != beneficiary) {
      require(newBeneficiary == approvedBeneficiary, "TitleEscrow: Beneficiary has not been endorsed by beneficiary");
      require(newHolder == approvedHolder, "TitleEscrow: Holder has not been endorsed by beneficiary");
    }
    _;
  }

  modifier isHoldingToken() {
    require(_tokenId != uint256(0), "TitleEscrow: Contract is not holding a token");
    require(status == StatusTypes.InUse, "TitleEscrow: Contract is not in use");
    require(tokenRegistry.ownerOf(_tokenId) == address(this), "TitleEscrow: Contract is not the owner of token");
    _;
  }

  modifier whenNotPaused() {
    bool paused = Pausable(address(tokenRegistry)).paused();
    require(!paused, "TitleEscrow: Token Registry is paused");
    _;
  }

  function _transferTo(address newOwner) internal {
    status = StatusTypes.Exited;
    emit TitleCeded(address(tokenRegistry), newOwner, _tokenId);
    tokenRegistry.safeTransferFrom(address(this), address(newOwner), _tokenId);
  }

  function surrender() external override whenNotPaused isHoldingToken onlyBeneficiary onlyHolder {
    _transferTo(address(tokenRegistry));

    emit Surrender(address(tokenRegistry), _tokenId, beneficiary);
  }

  function transferToNewEscrow(address newBeneficiary, address newHolder)
    public
    override
    whenNotPaused
    isHoldingToken
    onlyHolder
    allowTransferTitleEscrow(newBeneficiary, newHolder)
  {
    address newTitleEscrowAddress = titleEscrowFactory.create(address(tokenRegistry), newBeneficiary, newHolder);
    _transferTo(newTitleEscrowAddress);
  }

  function approveNewTransferTargets(address newBeneficiary, address newHolder)
    public
    override
    whenNotPaused
    onlyBeneficiary
    isHoldingToken
  {
    require(newBeneficiary != address(0), "TitleEscrow: Transferring to 0x0 is not allowed");
    require(newHolder != address(0), "TitleEscrow: Transferring to 0x0 is not allowed");

    emit TransferTitleEscrowApproval(newBeneficiary, newHolder);

    approvedBeneficiary = newBeneficiary;
    approvedHolder = newHolder;
  }
}
