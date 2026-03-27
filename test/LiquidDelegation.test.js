// SPDX-License-Identifier: MIT
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LiquidDelegationVault", function () {
  let vault, token, owner, delegate, voter;
  let DEPOSIT_AMOUNT = ethers.parseEther("1000");

  beforeEach(async function () {
    [owner, delegate, voter] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("ERC20");
    token = await Token.deploy("Test Token", "TST");
    await token.mint(owner.address, ethers.parseEther("10000"));
    
    const Vault = await ethers.getContractFactory("LiquidDelegationVault");
    vault = await Vault.deploy(await token.getAddress(), "LiquidStake", "LST");
    await vault.deployed();
    await token.approve(vault.target, DEPOSIT_AMOUNT);
  });

  it("should deposit and mint shares", async function () {
    const shares = await vault.previewDeposit(DEPOSIT_AMOUNT);
    await vault.deposit(DEPOSIT_AMOUNT, owner.address);
    expect(await vault.balanceOf(owner.address)).to.equal(shares);
    expect(await vault.totalAssets()).to.equal(DEPOSIT_AMOUNT);
  });

  it("should allow delegate to stake", async function () {
    await vault.connect(delegate).stake(DEPOSIT_AMOUNT);
    expect(await vault.delegateStakes(delegate.address)).to.equal(DEPOSIT_AMOUNT);
    expect(await vault.delegateVotingPower(delegate.address)).to.be.greaterThan(0);
  });

  it("should record vote and update voting power", async function () {
    await vault.connect(delegate).stake(DEPOSIT_AMOUNT);
    await vault.recordVote(delegate.address, 1, ethers.parseEther("100"));
    const record = await vault.voteRecords(delegate.address, 0);
    expect(record.proposalId).to.equal(1);
    expect(record.weight).to.equal(ethers.parseEther("100"));
  });

  it("should slash delegate for deviation", async function () {
    await vault.connect(delegate).stake(DEPOSIT_AMOUNT);
    const initialBalance = await vault.balanceOf(delegate.address);
    await vault.slash(delegate.address, ethers.parseEther("100"), "deviation");
    const finalBalance = await vault.balanceOf(delegate.address);
    expect(finalBalance).to.be.lessThan(initialBalance);
  });

  it("should allow withdraw/redeem", async function () {
    await vault.deposit(DEPOSIT_AMOUNT, owner.address);
    const shares = await vault.balanceOf(owner.address);
    await vault.redeem(shares, owner.address, owner.address);
    expect(await vault.balanceOf(owner.address)).to.equal(0);
  });
});

describe("GovernanceProposal", function () {
  let proposal, vault, token, owner, voter;
  let VOTING_DURATION = 86400;

  beforeEach(async function () {
    [owner, voter] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("ERC20");
    token = await Token.deploy("Test Token", "TST");
    await token.mint(owner.address, ethers.parseEther("10000"));
    
    const Vault = await ethers.getContractFactory("LiquidDelegationVault");
    vault = await Vault.deploy(await token.getAddress(), "LiquidStake", "LST");
    await vault.deployed();
    
    const Proposal = await ethers.getContractFactory("GovernanceProposal");
    proposal = await Proposal.deploy(await vault.getAddress());
    await proposal.deployed();
    await vault.setGovernance(await proposal.getAddress());
  });

  it("should create proposal with correct state", async function () {
    const tx = await proposal.createProposal(
      "Test Proposal",
      "https://ipfs.io/ipfs/test",
      owner.address
    );
    const receipt = await tx.wait();
    const event = receipt.events.find(e => e.event === "ProposalCreated");
    expect(event.args.proposalId).to.equal(1);
    expect(event.args.votingStart).to.be.greaterThan(0);
    expect(event.args.votingEnd).to.be.greaterThan(event.args.votingStart);
  });

  it("should allow voting during active period", async function () {
    await proposal.createProposal("Test", "https://ipfs.io/ipfs/test", owner.address);
    await ethers.provider.send("evm_increaseTime", [VOTING_DURATION + 1]);
    await ethers.provider.send("evm_mine");
    
    await proposal.connect(voter).castVote(1, true, ethers.parseEther("100"));
    const proposalData = await proposal.proposals(1);
    expect(proposalData.yesVotes).to.equal(ethers.parseEther("100"));
  });

  it("should execute proposal when quorum reached", async function () {
    await proposal.createProposal("Test", "https://ipfs.io/ipfs/test", owner.address);
    await ethers.provider.send("evm_increaseTime", [VOTING_DURATION + 1]);
    await ethers.provider.send("evm_mine");
    
    await proposal.connect(voter).castVote(1, true, ethers.parseEther("1000"));
    await proposal.execute(1);
    
    const proposalData = await proposal.proposals(1);
    expect(proposalData.executed).to.be.true;
  });

  it("should prevent voting after proposal executed", async function () {
    await proposal.createProposal("Test", "https://ipfs.io/ipfs/test", owner.address);
    await ethers.provider.send("evm_increaseTime", [VOTING_DURATION + 1]);
    await ethers.provider.send("evm_mine");
    
    await proposal.connect(voter).castVote(1, true, ethers.parseEther("1000"));
    await proposal.execute(1);
    
    await expect(proposal.connect(voter).castVote(1, false, ethers.parseEther("100")))
      .to.be.revertedWith("Proposal already executed");
  });
});

describe("ReputationOracle", function () {
  let oracle, vault, proposal, token, owner, delegate, voter;

  beforeEach(async function () {
    [owner, delegate, voter] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("ERC20");
    token = await Token.deploy("Test Token", "TST");
    await token.mint(owner.address, ethers.parseEther("10000"));
    
    const Vault = await ethers.getContractFactory("LiquidDelegationVault");
    vault = await Vault.deploy(await token.getAddress(), "LiquidStake", "LST");
    await vault.deployed();
    
    const Proposal = await ethers.getContractFactory("GovernanceProposal");
    proposal = await Proposal.deploy(await vault.getAddress());
    await proposal.deployed();
    
    const Oracle = await ethers.getContractFactory("ReputationOracle");
    oracle = await Oracle.deploy(await vault.getAddress(), await proposal.getAddress());
    await oracle.deployed();
    
    await vault.setGovernance(await proposal.getAddress());
    await vault.setOracle(await oracle.getAddress());
  });

  it("should detect deviation and slash delegate", async function () {
    await vault.connect(delegate).stake(ethers.parseEther("1000"));
    await proposal.createProposal("Test", "https://ipfs.io/ipfs/test", owner.address);
    await ethers.provider.send("evm_increaseTime", [86401]);
    await ethers.provider.send("evm_mine");
    
    await proposal.connect(voter).castVote(1, true, ethers.parseEther("1000"));
    await oracle.checkDeviation(1, delegate.address, false);
    
    const reputation = await oracle.delegateReputation(delegate.address);
    expect(reputation.deviationCount).to.be.greaterThan(0);
  });

  it("should calculate consensus correctly", async function () {
    await proposal.createProposal("Test", "https://ipfs.io/ipfs/test", owner.address);
    await ethers.provider.send("evm_increaseTime", [86401]);
    await ethers.provider.send("evm_mine");
    
    await proposal.connect(voter).castVote(1, true, ethers.parseEther("1000"));
    await oracle.calculateConsensus(1);
    
    const consensus = await oracle.proposalConsensus(1);
    expect(consensus).to.be.true;
  });

  it("should track vote records for delegate", async function () {
    await vault.connect(delegate).stake(ethers.parseEther("1000"));
    await proposal.createProposal("Test", "https://ipfs.io/ipfs/test", owner.address);
    await ethers.provider.send("evm_increaseTime", [86401]);
    await ethers.provider.send("evm_mine");
    
    await proposal.connect(delegate).castVote(1, true, ethers.parseEther("100"));
    await oracle.recordVote(delegate.address, 1, true);
    
    const votes = await oracle.delegateVotes(delegate.address, 0);
    expect(votes.proposalId).to.equal(1);
    expect(votes.support).to.be.true;
  });
});