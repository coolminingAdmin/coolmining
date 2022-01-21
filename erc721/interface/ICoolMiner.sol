// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICoolMiner {
    struct TokensViewFront {
        uint tokenId;
        address tokenOwner;
        uint128 hashPower;
        uint128 gasRatio;
        uint128 feeRatio;
        uint32 createTimestamp;
        string uri;
    }

    function getToken(uint _tokenId) external view returns (TokensViewFront memory);

    function mint(
        address to,
        uint128 hashPower,
        uint128 gasRatio,
        uint128 feeRatio
    ) external returns (uint);

    function getTokensByIds(uint[] calldata _tokenIds) external view returns (TokensViewFront[] memory);

    function tokenOfOwnerByIndex(address owner, uint index) external view returns (uint tokenId);

    // function arrayUserPlayers(address _user) external view returns (TokensViewFront[] memory);

    function balanceOf(address owner) external view returns (uint balance);

    function ownerOf(uint tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function burn(uint _tokenId) external;
}
