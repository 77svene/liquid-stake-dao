// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract GovernanceProposal {
    enum ProposalState { Pending, Active, Executed, Cancelled }
    
    struct Proposal {
        uint256 id;
        string title;
        string description;
        address proposer;
        uint256 votingStart;
        uint256 votingEnd;
        uint256 yesVotes;
        uint256 noVotes;
        ProposalState state;
        bool executed;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    address public vault;
    
    uint256 public proposalCount;
    uint256 public constant VOTING_DURATION = 1 days;
    uint256 public constant QUORUM_PERCENTAGE = 10;
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, uint256 votingStart, uint256 votingEnd);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    
    constructor(address _vault) {
        vault = _vault;
    }
    
    function setVault(address _vault) external {
        vault = _vault;
    }
    
    function createProposal(string memory _title, string memory _description) external returns (uint256) {
        require(bytes(_title).length > 0, "Empty title");
        require(bytes(_description).length > 0, "Empty description");
        
        uint256 proposalId = proposalCount++;
        uint256 votingStart = block.timestamp;
        uint256 votingEnd = votingStart + VOTING_DURATION;
        
        proposals[proposalId] = Proposal({
            id: proposalId,
            title: _title,
            description: _description,
            proposer: msg.sender,
            votingStart: votingStart,
            votingEnd: votingEnd,
            yesVotes: 0,
            noVotes: 0,
            state: ProposalState.Active,
            executed: false
        });
        
        emit ProposalCreated(proposalId, msg.sender, votingStart, votingEnd);
        return proposalId;
    }
    
    function castVote(uint256 _proposalId, bool _support) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Not active");
        require(!hasVoted[_proposalId][msg.sender], "Already voted");
        require(block.timestamp >= proposal.votingStart, "Not started");
        require(block.timestamp <= proposal.votingEnd, "Voting ended");
        
        uint256 votingPower = _getVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");
        
        hasVoted[_proposalId][msg.sender] = true;
        
        if (_support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }
    
    function _getVotingPower(address _delegate) internal view returns (uint256) {
        if (vault != address(0)) {
            try IERC4626(vault).delegateVotingPower(_delegate) returns (uint256 power) {
                return power;
            } catch {
                return 0;
            }
        }
        return 0;
    }
    
    function executeProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.state == ProposalState.Active, "Not active");
        require(block.timestamp > proposal.votingEnd, "Voting not ended");
        
        uint256 totalVotes = proposal.yesVotes + proposal.noVotes;
        uint256 quorum = (totalVotes * QUORUM_PERCENTAGE) / 100;
        require(proposal.yesVotes >= quorum, "Quorum not met");
        require(proposal.yesVotes > proposal.noVotes, "Proposal rejected");
        
        proposal.state = ProposalState.Executed;
        proposal.executed = true;
        
        emit ProposalExecuted(_proposalId);
    }
    
    function cancelProposal(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.proposer == msg.sender, "Not proposer");
        require(proposal.state == ProposalState.Active, "Not active");
        
        proposal.state = ProposalState.Cancelled;
        
        emit ProposalCancelled(_proposalId);
    }
    
    function getProposalState(uint256 _proposalId) external view returns (ProposalState) {
        return proposals[_proposalId].state;
    }
}