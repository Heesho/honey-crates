// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Box is ERC721Enumerable, Ownable {
    string private _baseTokenURI;

    /*----------  CONSTANTS  --------------------------------------------*/

    /*----------  STATE VARIABLES  --------------------------------------*/

    address public treasury;
    address public developer;
    address public incentives;

    uint256 public price = 0.01 ether;

    /*----------  ERRORS ------------------------------------------------*/

    error Box__InvalidZeroAddress();
    error Box__NotDeveloper();
    error Box__InvalidPrice();

    /*----------  EVENTS ------------------------------------------------*/

    event Box__Distributed(uint256 developerAmount, uint256 treasuryAmount, uint256 incentivesAmount);
    event Box__PriceSet(uint256 price);
    event Box__TreasurySet(address treasury);
    event Box__DeveloperSet(address developer);
    event Box__IncentivesSet(address incentives);
    event Box__Buy(address to, uint256 tokenId);
    event Box__Burn(address from, uint256 tokenId);
    event Box__Mint(address to, uint256 tokenId);

    /*----------  MODIFIERS  --------------------------------------------*/

    /*----------  FUNCTIONS  --------------------------------------------*/
    
    constructor(string memory baseTokenURI_) ERC721("HoneyCrates Box", "HCB") {
        _baseTokenURI = baseTokenURI_;
    }

    function buy(address to) external payable returns (uint256) {
        if (msg.value < price) revert Box__InvalidPrice();
        uint256 tokenId = totalSupply();
        _safeMint(to, tokenId);
        emit Box__Buy(to, tokenId);
        return tokenId;
    }
    
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner or approved");
        _burn(tokenId);
        emit Box__Burn(msg.sender, tokenId);
    }

    function distribute() external {
        uint256 balance = address(this).balance;
        uint256 incentivesAmount = balance * 80 / 100;
        uint256 developerAmount = balance * 10 / 100;
        uint256 treasuryAmount = balance - incentivesAmount - developerAmount;

        payable(treasury).transfer(treasuryAmount);
        payable(developer).transfer(developerAmount);
        payable(incentives).transfer(incentivesAmount);

        emit Box__Distributed(developerAmount, treasuryAmount, incentivesAmount);
    }

    /*----------  RESTRICTED FUNCTIONS  ---------------------------------*/

    function mint(address to) external onlyOwner returns (uint256) {
        uint256 tokenId = totalSupply();
        _safeMint(to, tokenId);
        emit Box__Mint(to, tokenId);
        return tokenId;
    }

    function setBaseURI(string memory baseTokenURI_) external onlyOwner {
        _baseTokenURI = baseTokenURI_;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit Box__PriceSet(price);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert Box__InvalidZeroAddress();
        treasury = _treasury;
        emit Box__TreasurySet(treasury);
    }

    function setDeveloper(address _developer) external {
        if (msg.sender != developer) revert Box__NotDeveloper();
        if (_developer == address(0)) revert Box__InvalidZeroAddress();
        developer = _developer;
        emit Box__DeveloperSet(developer);
    }

    function setIncentives(address _incentives) external onlyOwner {
        if (_incentives == address(0)) revert Box__InvalidZeroAddress();
        incentives = _incentives;
        emit Box__IncentivesSet(incentives);
    }

    /*----------  VIEW FUNCTIONS  ---------------------------------------*/

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

}