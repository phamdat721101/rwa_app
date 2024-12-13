// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RealEstateTokenization is Ownable {
    struct RealEstate {
        uint256 id;
        string name;
        string location;
        uint256 totalValue; // Total value of the property in wei
        address tokenAddress; // Address of the ERC20 token contract for fractional ownership
        uint256 totalYieldDistributed; // Total yield distributed to date for this property
        mapping(address => uint256) userClaimedYield; // Track how much yield each user has claimed
        bool isTokenized;
    }

    uint256 public nextId = 1;
    mapping(uint256 => RealEstate) public realEstates;

    event RealEstateCreated(uint256 indexed id, string name, string location, uint256 totalValue);
    event RealEstateTokenized(uint256 indexed id, address tokenAddress);
    event YieldDistributed(uint256 indexed realEstateId, uint256 amount);
    event YieldClaimed(uint256 indexed realEstateId, address indexed user, uint256 amount);

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Create a new real estate entry
    function createRealEstate(string memory name, string memory location, uint256 totalValue) external onlyOwner {
        require(totalValue > 0, "Total value must be greater than 0");

        RealEstate storage realEstate = realEstates[nextId];
        realEstate.id = nextId;
        realEstate.name = name;
        realEstate.location = location;
        realEstate.totalValue = totalValue;
        realEstate.isTokenized = false;

        emit RealEstateCreated(nextId, name, location, totalValue);
        nextId++;
    }

    // Tokenize the real estate into fractional ownership tokens
    function tokenizeRealEstate(uint256 id, string memory tokenName, string memory tokenSymbol, uint256 totalSupply) external onlyOwner {
        RealEstate storage realEstate = realEstates[id];
        require(!realEstate.isTokenized, "Already tokenized");
        require(totalSupply > 0, "Total supply must be greater than 0");

        // Deploy a new ERC20 token for the real estate
        RealEstateToken token = new RealEstateToken(tokenName, tokenSymbol, totalSupply, msg.sender);

        // Update real estate details
        realEstate.tokenAddress = address(token);
        realEstate.isTokenized = true;

        emit RealEstateTokenized(id, address(token));
    }

    // Distribute yield for a tokenized real estate
    function distributeYield(uint256 realEstateId) external payable onlyOwner {
        RealEstate storage realEstate = realEstates[realEstateId];
        require(realEstate.isTokenized, "Real estate is not tokenized");
        require(msg.value > 0, "Yield amount must be greater than 0");

        realEstate.totalYieldDistributed += msg.value;

        emit YieldDistributed(realEstateId, msg.value);
    }

    // Claim yield for a specific real estate
    function claimYield(uint256 realEstateId) external {
        RealEstate storage realEstate = realEstates[realEstateId];
        require(realEstate.isTokenized, "Real estate is not tokenized");

        address tokenAddress = realEstate.tokenAddress;
        RealEstateToken token = RealEstateToken(tokenAddress);

        uint256 userBalance = token.balanceOf(msg.sender);
        require(userBalance > 0, "No tokens owned");

        uint256 totalSupply = token.totalSupply();
        uint256 userShare = (realEstate.totalYieldDistributed * userBalance) / totalSupply;
        uint256 claimableYield = userShare - realEstate.userClaimedYield[msg.sender];

        require(claimableYield > 0, "No yield to claim");

        // Update claimed yield
        realEstate.userClaimedYield[msg.sender] += claimableYield;

        // Transfer yield
        payable(msg.sender).transfer(claimableYield);

        emit YieldClaimed(realEstateId, msg.sender, claimableYield);
    }

    // Get details of a real estate
    function getRealEstate(uint256 id) external view returns (string memory name, string memory location, uint256 totalValue, address tokenAddress, bool isTokenized, uint256 totalYieldDistributed) {
        RealEstate storage realEstate = realEstates[id];
        return (
            realEstate.name,
            realEstate.location,
            realEstate.totalValue,
            realEstate.tokenAddress,
            realEstate.isTokenized,
            realEstate.totalYieldDistributed
        );
    }
}

// ERC20 token contract for fractional ownership
contract RealEstateToken is ERC20, Ownable {
    constructor(string memory name, string memory symbol, uint256 totalSupply, address admin) ERC20(name, symbol) Ownable(admin) {
        _mint(admin, totalSupply);
    }

    // Allow token holder to buy/sell tokens by transferring
    function buyTokens(address to, uint256 amount) external onlyOwner {
        _transfer(owner(), to, amount);
    }
}
