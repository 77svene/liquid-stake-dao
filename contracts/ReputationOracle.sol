// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./LiquidDelegationVault.sol";
import "./GovernanceProposal.sol";

contract ReputationOracle {
    LiquidDelegationVault public vault;
    GovernanceProposal public governance;
    
    uint256 public constant SLASHING_THRESHOLD = 50; // 50% deviation triggers slashing
    uint256 public constant SLASHING_PERCENTAGE = 10; // 10% of stake slashed
    uint256 public constant MAX_VOTES_PER_PROPOSAL = 100;
    
    struct VoteRecord {
        uint256 proposalId;
        bool support;
        uint256 timestamp;
    }
    
    struct DelegateReputation {
        uint256 totalVotes;
        uint256 deviationCount;
        uint256 lastSlashAmount;
    }
    
    mapping(uint256 => bool) public proposalConsensus;
    mapping(uint256 => bool) public consensusCalculated;
    mapping(address => DelegateReputation) public delegateReputation;
    mapping(uint256 => VoteRecord[]) public delegateVotes;
    
    event DeviationDetected(address indexed delegate, uint256 proposalId, uint256 deviation);
    event Slashed(address indexed delegate, uint256 amount, uint256 deviation);
    event ConsensusCalculated(uint256 indexed proposalId, bool consensus);
    
    constructor(address _vault, address _governance) {
        vault = LiquidDelegationVault(_vault);
        governance = GovernanceProposal(_governance);
    }
    
    function calculateConsensus(uint256 proposalId) external returns (bool consensus) {
        require(consensusCalculated[proposalId] == false, "Already calculated");
        
        uint256 yesVotes = governance.proposals(proposalId).yesVotes;
        uint256 noVotes = governance.proposals(proposalId).noVotes;
        uint256 totalVotes = yesVotes + noVotes;
        
        if (totalVotes == 0) {
            proposalConsensus[proposalId] = false;
            consensusCalculated[proposalId] = true;
            return false;
        }
        
        consensus = (yesVotes * 100) / totalVotes > 50;
        proposalConsensus[proposalId] = consensus;
        consensusCalculated[proposalId] = true;
        
        emit ConsensusCalculated(proposalId, consensus);
    }
    
    function checkDelegateDeviation(address delegate, uint256 proposalId) external returns (uint256 deviation) {
        require(consensusCalculated[proposalId], "Consensus not calculated");
        
        VoteRecord[] storage votes = delegateVotes[proposalId];
        uint256 delegateVoteCount = votes.length;
        
        if (delegateVoteCount == 0) return 0;
        
        VoteRecord memory lastVote = votes[delegateVoteCount - 1];
        bool delegateVotedYes = lastVote.support;
        bool consensus = proposalConsensus[proposalId];
        
        if (delegateVotedYes != consensus) {
            deviation = 100;
            emit DeviationDetected(delegate, proposalId, deviation);
        } else {
            deviation = 0;
        }
        
        return deviation;
    }
    
    function slashDelegate(address delegate, uint256 deviation) external returns (uint256 slashedAmount) {
        require(deviation >= SLASHING_THRESHOLD, "Deviation below threshold");
        
        uint256 delegateStake = vault.delegateStakes(delegate);
        require(delegateStake > 0, "No stake to slash");
        
        slashedAmount = (delegateStake * SLASHING_PERCENTAGE) / 100;
        require(slashedAmount > 0, "Slashing amount too small");
        
        vault.delegateStakes[delegate] = delegateStake - slashedAmount;
        
        DelegateReputation storage rep = delegateReputation[delegate];
        rep.deviationCount += 1;
        rep.lastSlashAmount = slashedAmount;
        
        emit Slashed(delegate, slashedAmount, deviation);
    }
    
    function recordVote(address delegate, uint256 proposalId, bool support) external {
        require(delegateVotes[proposalId].length < MAX_VOTES_PER_PROPOSAL, "Too many votes");
        
        VoteRecord memory record = VoteRecord(proposalId, support, block.timestamp);
        delegateVotes[proposalId].push(record);
        
        DelegateReputation storage rep = delegateReputation[delegate];
        rep.totalVotes += 1;
    }
    
    function getDelegateReputation(address delegate) external view returns (DelegateReputation memory) {
        return delegateReputation[delegate];
    }
    
    function getProposalConsensus(uint256 proposalId) external view returns (bool) {
        return proposalConsensus[proposalId];
    }
}