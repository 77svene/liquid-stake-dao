// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LiquidDelegationVault is ERC20, IERC4626, ReentrancyGuard {
    address public immutable asset;
    uint256 public totalManagedAssets;
    mapping(address => uint256) public delegateStakes;
    mapping(address => uint256) public delegateVotingPower;
    
    event DelegateStaked(address indexed delegate, uint256 amount);
    event DelegateUnstaked(address indexed delegate, uint256 amount);
    event VoteRecorded(address indexed delegate, uint256 proposalId, uint256 weight);
    event Slashed(address indexed delegate, uint256 amount, string reason);

    constructor(address _asset, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        asset = _asset;
    }

    function totalAssets() public view override returns (uint256) {
        return totalManagedAssets;
    }

    function totalShares() public view override returns (uint256) {
        return totalSupply();
    }

    function previewDeposit(uint256 assets) public view override returns (uint256) {
        if (totalAssets() == 0) return assets;
        return (assets * totalShares()) / totalAssets();
    }

    function previewMint(uint256 shares) public view override returns (uint256) {
        if (totalShares() == 0) return shares;
        return (shares * totalAssets()) / totalShares();
    }

    function deposit(uint256 assets, address receiver) public override nonReentrant returns (uint256) {
        uint256 shares = previewDeposit(assets);
        _deposit(assets, receiver, shares);
        return shares;
    }

    function mint(uint256 shares, address receiver) public override nonReentrant returns (uint256) {
        uint256 assets = previewMint(shares);
        _deposit(assets, receiver, shares);
        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) public override nonReentrant returns (uint256) {
        uint256 shares = previewWithdraw(assets);
        _withdraw(assets, receiver, owner, shares);
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public override nonReentrant returns (uint256) {
        uint256 assets = previewRedeem(shares);
        _withdraw(assets, receiver, owner, shares);
        return assets;
    }

    function _deposit(uint256 assets, address receiver, uint256 shares) internal {
        require(assets > 0, "Assets must be positive");
        uint256 balanceBefore = IERC20(asset).balanceOf(address(this));
        require(IERC20(asset).transferFrom(msg.sender, address(this), assets), "Transfer failed");
        uint256 balanceAfter = IERC20(asset).balanceOf(address(this));
        require(balanceAfter >= balanceBefore, "Balance check failed");
        totalManagedAssets += assets;
        _mint(receiver, shares);
    }

    function _withdraw(uint256 assets, address receiver, address owner, uint256 shares) internal {
        require(shares > 0, "Shares must be positive");
        require(owner == msg.sender || isApprovedForAll(owner, msg.sender), "Not authorized");
        uint256 balanceBefore = IERC20(asset).balanceOf(address(this));
        _burn(owner, shares);
        totalManagedAssets -= assets;
        require(IERC20(asset).transfer(receiver, assets), "Transfer failed");
        uint256 balanceAfter = IERC20(asset).balanceOf(address(this));
        require(balanceAfter <= balanceBefore, "Balance check failed");
    }

    function stakeDelegate(address delegate, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be positive");
        delegateStakes[delegate] += amount;
        delegateVotingPower[delegate] += amount;
        emit DelegateStaked(delegate, amount);
    }

    function unstakeDelegate(address delegate, uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be positive");
        require(delegateStakes[delegate] >= amount, "Insufficient stake");
        delegateStakes[delegate] -= amount;
        delegateVotingPower[delegate] -= amount;
        emit DelegateUnstaked(delegate, amount);
    }

    function recordVote(address delegate, uint256 proposalId, uint256 weight) external {
        require(delegateStakes[delegate] > 0, "Delegate not staked");
        emit VoteRecorded(delegate, proposalId, weight);
    }

    function slashDelegate(address delegate, uint256 amount, string memory reason) external {
        require(delegateStakes[delegate] >= amount, "Insufficient stake");
        delegateStakes[delegate] -= amount;
        delegateVotingPower[delegate] -= amount;
        emit Slashed(delegate, amount, reason);
    }

    function getDelegateRisk(address delegate) external view returns (uint256) {
        uint256 stake = delegateStakes[delegate];
        uint256 votingPower = delegateVotingPower[delegate];
        if (stake == 0) return 0;
        return (votingPower * 10000) / stake;
    }
}