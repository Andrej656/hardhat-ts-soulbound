// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract SoulboundNFT is ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    using Address for address;

    Counters.Counter private _tokenIdCounter;

    // Mapping to track if an NFT is soulbound
    mapping(uint256 => bool) private _soulbound;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    // Mint a new NFT
    function mint(address to) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _mint(to, tokenId);
        _tokenIdCounter.increment();
        emit Minted(msg.sender, to, tokenId);
    }

    // Mark an NFT as soulbound
    function setSoulbound(uint256 tokenId) external onlyOwner {
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == owner(), "Only the owner can set soulbound status");
        _soulbound[tokenId] = true;
        emit SoulboundSet(tokenId);
    }

    // Check if an NFT is soulbound
    function isSoulbound(uint256 tokenId) external view returns (bool) {
        require(_exists(tokenId), "Token does not exist");
        return _soulbound[tokenId];
    }

    // Override _baseURI to provide a base URI for metadata (optional)
    function _baseURI() internal pure override returns (string memory) {
        return "https://your-base-uri.com/token/";
    }

    // Safe transfer function that checks for soulbound status
    function safeTransferFromWithCheck(
        address from,
        address to,
        uint256 tokenId
    ) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Transfer caller is not owner nor approved");
        require(!_soulbound[tokenId] || owner() == from, "Soulbound token can only be transferred by the owner");
        safeTransferFrom(from, to, tokenId);
        emit TransferWithCheck(from, to, tokenId);
    }

    // Withdraw funds from the contract (for royalties, etc.)
    function withdrawBalance() external onlyOwner {
        address payable ownerPayable = payable(owner());
        ownerPayable.transfer(address(this).balance);
        emit BalanceWithdrawn(ownerPayable, address(this).balance);
    }

    // Events for transparency
    event Minted(address indexed owner, address indexed to, uint256 indexed tokenId);
    event SoulboundSet(uint256 indexed tokenId);
    event TransferWithCheck(address indexed from, address indexed to, uint256 indexed tokenId);
    event BalanceWithdrawn(address indexed owner, uint256 amount);
}
