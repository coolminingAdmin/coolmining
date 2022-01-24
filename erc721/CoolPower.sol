// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract CoolPower is
    Initializable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant TOKEN_MINTER_ROLE = keccak256("TOKEN_MINTER");

    string private _internalBaseURI;
    uint private _lastTokenId;
    uint128[5] private _rarityMainProp;

    struct Token {
        uint8 rarity; //Token rarity (Star)
        uint32 createTimestamp;
        uint128 mainProp;
    }

    struct TokensViewFront {
        uint tokenId;
        uint8 rarity;
        address tokenOwner;
        uint128 mainProp;
        uint32 createTimestamp;
        string uri;
    }

    mapping(uint => Token) private _tokens; // TokenId => Token

    event Initialize(string baseURI);
    event TokenMint(address indexed to, uint indexed tokenId, uint8 rarity, uint128 mainProp);

    //Initialize function --------------------------------------------------------------------------------------------

    function initialize(string memory baseURI) public virtual initializer {
        __ERC721_init('CoolPower', 'CAPW');
        __ERC721Enumerable_init();
        __AccessControl_init_unchained();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TOKEN_MINTER_ROLE, msg.sender);
        _setRoleAdmin(TOKEN_MINTER_ROLE, DEFAULT_ADMIN_ROLE);

        _rarityMainProp[0] = 95_000_000;
        _rarityMainProp[1] = 85_000_000;
        _rarityMainProp[2] = 75_000_000;
        _internalBaseURI = baseURI;
        emit Initialize(baseURI);
    }

    //External functions --------------------------------------------------------------------------------------------

    function setBaseURI(string calldata newBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _internalBaseURI = newBaseUri;
    }

    function setRarityMainPropTable(uint128[5] calldata newRarityMainProps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _rarityMainProp = newRarityMainProps;
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

//    function fix(uint max) external onlyRole(DEFAULT_ADMIN_ROLE) {
//        for(uint i = 0; i < max; i++){
//            Token storage token = _tokens[i];
//            if (token.mainProp < 1000) {
//                token.mainProp = token.mainProp * 1_000_000;
//            }
//        }
//    }

    function mint(
        address to,
        // uint32 mainProp,
        uint8 rarity
    ) public onlyRole(TOKEN_MINTER_ROLE) nonReentrant returns (uint, uint128){
        require(to != address(0), "Address can not be zero");
        require(rarity < _rarityMainProp.length, "Wrong rarity");
        // require(mainProp <= _rarityMainProp[rarity], "Main Prop over rarity limit");
        _lastTokenId += 1;
        uint tokenId = _lastTokenId;
        _tokens[tokenId].rarity = rarity;
        _tokens[tokenId].mainProp = _rarityMainProp[rarity];// mainProp;
        _tokens[tokenId].createTimestamp = uint32(block.timestamp);
        _safeMint(to, tokenId);
        return (tokenId, _tokens[tokenId].mainProp);
    }

    function burn(uint _tokenId) public {
        require(_exists(_tokenId), "ERC721: token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "Not token owner");
        _burn(_tokenId);
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

    function getToken(uint _tokenId) public view returns (TokensViewFront memory) {
        require(_exists(_tokenId), "ERC721: token does not exist");
        Token memory token = _tokens[_tokenId];
        TokensViewFront memory tokenReturn;
        tokenReturn.tokenId = _tokenId;
        tokenReturn.rarity = token.rarity;
        tokenReturn.tokenOwner = ownerOf(_tokenId);
        tokenReturn.mainProp = token.mainProp;
        tokenReturn.createTimestamp = token.createTimestamp;
        tokenReturn.uri = tokenURI(_tokenId);
        return (tokenReturn);
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
        emit TokenMint(to, tokenId, _tokens[tokenId].rarity, _tokens[tokenId].mainProp);
    }

}
