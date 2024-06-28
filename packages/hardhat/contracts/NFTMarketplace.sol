// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721Enumerable, Ownable {
    using Address for address payable;

    struct Sale {
        address seller;
        uint256 price;
        bool active;
    }

    mapping(uint256 => Sale) public tokenIdToSale;

    event NFTListed(uint256 tokenId, uint256 price);
    event NFTSold(uint256 tokenId, address buyer, uint256 price);

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function listNFT(uint256 tokenId, uint256 price) external {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to sell");
        tokenIdToSale[tokenId] = Sale({seller: msg.sender, price: price, active: true});
        emit NFTListed(tokenId, price);
    }

    function buyNFT(uint256 tokenId) external payable {
        Sale storage sale = tokenIdToSale[tokenId];
        require(sale.active, "NFT not for sale");
        require(msg.value >= sale.price, "Insufficient payment");

        address payable seller = payable(sale.seller);
        seller.sendValue(msg.value);
        
        _transfer(sale.seller, _msgSender(), tokenId);
        delete tokenIdToSale[tokenId];
        emit NFTSold(tokenId, _msgSender(), sale.price);
    }

    function cancelSale(uint256 tokenId) external {
        Sale storage sale = tokenIdToSale[tokenId];
        require(sale.active, "Sale already cancelled");
        require(_msgSender() == sale.seller, "Not the seller");

        delete tokenIdToSale[tokenId];
        emit NFTListed(tokenId, 0);
    }

    function withdrawFunds() external onlyOwner {
        address payable owner = payable(owner());
        owner.sendValue(address(this).balance);
    }

    function availableBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}