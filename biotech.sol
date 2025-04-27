// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BiotechInvestmentBundle
 * @dev NFT + fractional ownership for biotech investments.
 */
contract BiotechInvestmentBundle is ERC721URIStorage, Ownable {
    uint256 private _bundleIdCounter;

    struct Ownership {
        mapping(address => uint256) shares; // address => percentage (0-10000 basis points = 100%)
        uint256 totalSold; // total percentage sold (in basis points)
        uint256 totalValue; // total value (price) of the bundle
        bool active;
    }

    mapping(uint256 => Ownership) private _ownerships;

    event SharePurchased(uint256 bundleId, address buyer, uint256 sharePercent);

    constructor() ERC721("BiotechInvestmentBundle", "BIOB") Ownable(msg.sender) {
    _bundleIdCounter = 1;
}


    function mintBundle(string memory tokenURI_, uint256 totalValue_) public onlyOwner {
        uint256 bundleId = _bundleIdCounter;
        _bundleIdCounter++;

        _mint(msg.sender, bundleId);
        _setTokenURI(bundleId, tokenURI_);

        Ownership storage ownership = _ownerships[bundleId];
        ownership.totalValue = totalValue_;
        ownership.active = true;
    }

    function buyShare(uint256 bundleId) public payable {
        Ownership storage ownership = _ownerships[bundleId];
        require(ownership.active, "Bundle not active");
        require(ownerOf(bundleId) != address(0), "Bundle does not exist");

        uint256 percent = (msg.value * 10000) / ownership.totalValue; // basis points calculation
        require(percent > 0, "Not enough to buy any share");
        require(ownership.totalSold + percent <= 10000, "Not enough shares left");

        ownership.shares[msg.sender] += percent;
        ownership.totalSold += percent;

        emit SharePurchased(bundleId, msg.sender, percent);
    }

    function getShare(uint256 bundleId, address user) public view returns (uint256) {
        return _ownerships[bundleId].shares[user];
    }

    function bundleInfo(uint256 bundleId) public view returns (uint256 totalValue, uint256 totalSold, bool active) {
        Ownership storage ownership = _ownerships[bundleId];
        return (ownership.totalValue, ownership.totalSold, ownership.active);
    }
}
