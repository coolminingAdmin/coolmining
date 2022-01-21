// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract CoolMiner is
Initializable,
ERC721EnumerableUpgradeable,
AccessControlUpgradeable,
ReentrancyGuardUpgradeable
{
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER");

    string private _internalBaseURI;
    uint private _lastTokenId;

    struct Token {
        uint32 createTimestamp;
        uint128 hashPower;
        uint128 gasRatio;
        uint128 feeRatio;
    }

    struct TokensViewFront {
        uint tokenId;
        address tokenOwner;
        uint128 hashPower;
        uint128 gasRatio;
        uint128 feeRatio;
        uint32 createTimestamp;
        string uri;
    }

    mapping(uint => Token) private _tokens; // TokenId => Token

    event Initialize(string baseURI);
    event TokenMint(address indexed to, uint indexed tokenId, uint128 hashPower, uint128 gasRatio, uint128 feeRatio);

    //Initialize function --------------------------------------------------------------------------------------------

    function initialize(string memory baseURI) public virtual initializer {
        __ERC721_init('CoolMiner', 'COMR');
        __ERC721Enumerable_init();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TOKEN_MINTER_ROLE, msg.sender);
        _setRoleAdmin(TOKEN_MINTER_ROLE, DEFAULT_ADMIN_ROLE);

        _internalBaseURI = baseURI;
        emit Initialize(baseURI);
    }

    //External functions --------------------------------------------------------------------------------------------

    function setBaseURI(string calldata newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _internalBaseURI = newBaseUri;
    }


    // //Public functions ----------------------------------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
    returns (bool)
    {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    function mint(
        address to,
        uint128 hashPower,
        uint128 gasRatio,
        uint128 feeRatio
    ) public onlyRole(TOKEN_MINTER_ROLE) nonReentrant returns (uint){
        require(to != address(0), "Address can not be zero");
        _lastTokenId += 1;
        uint tokenId = _lastTokenId;
        _tokens[tokenId].hashPower = hashPower;
        _tokens[tokenId].gasRatio = gasRatio;
        _tokens[tokenId].feeRatio = feeRatio;
        _tokens[tokenId].createTimestamp = uint32(block.timestamp);
        _safeMint(to, tokenId);
        return tokenId;
    }

    function burn(uint _tokenId) public {
        require(_exists(_tokenId), "ERC721: token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        _burn(_tokenId);
    }

    function getToken(uint _tokenId) public view returns (TokensViewFront memory) {
        require(_exists(_tokenId), "ERC721: token does not exist");
        Token memory token = _tokens[_tokenId];
        TokensViewFront memory tokenReturn;
        tokenReturn.tokenId = _tokenId;
        tokenReturn.tokenOwner = ownerOf(_tokenId);
        tokenReturn.hashPower = token.hashPower;
        tokenReturn.gasRatio = token.gasRatio;
        tokenReturn.feeRatio = token.feeRatio;
        tokenReturn.createTimestamp = token.createTimestamp;
        tokenReturn.uri = tokenURI(_tokenId);
        return (tokenReturn);
    }

    function getTokensByIds(uint[] calldata _tokenIds) public view returns (TokensViewFront[] memory) {
        TokensViewFront[] memory tokens = new TokensViewFront[](_tokenIds.length);
        uint index = 0;
        for (uint i = 0; i < _tokenIds.length; i++) {
            tokens[index] = getToken(_tokenIds[i]);
            index++;
        }
        return (tokens);
    }

    function getAllUserTokens(address _user) public view returns (TokensViewFront[] memory) {
        if (balanceOf(_user) == 0) return new TokensViewFront[](0);
        return getPageUserTokens(_user, 0, balanceOf(_user) - 1);
    }

    function getPageUserTokens(
        address _user,
        uint _from,
        uint _to
    ) public view returns (TokensViewFront[] memory) {
        require(_to < balanceOf(_user), "Wrong max array value");
        require((_to - _from) <= balanceOf(_user), "Wrong array range");
        TokensViewFront[] memory tokens = new TokensViewFront[](_to - _from + 1);
        uint index = 0;
        for (uint i = _from; i <= _to; i++) {
            uint id = tokenOfOwnerByIndex(_user, i);
            tokens[index] = getToken(id);
            index++;
        }
        return (tokens);
    }

    // //Internal functions --------------------------------------------------------------------------------------------

    function _baseURI() internal view override returns (string memory) {
        return _internalBaseURI;
    }

    function _burn(uint tokenId) internal override {
        super._burn(tokenId);
        delete _tokens[tokenId];
    }

    function _safeMint(address to, uint tokenId) internal override {
        super._safeMint(to, tokenId);
        emit TokenMint(to, tokenId, _tokens[tokenId].hashPower, _tokens[tokenId].gasRatio, _tokens[tokenId].feeRatio);
    }

}
