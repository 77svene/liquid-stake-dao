# LiquidStake DAO

Liquid delegation system where delegates stake capital to represent voters, enabling liquid delegation with automatic slashing for malicious voting patterns.

## Overview

- **LiquidDelegationVault**: ERC4626 vault for staking and delegation
- **GovernanceProposal**: Proposal creation and voting system
- **ReputationOracle**: Slashing mechanism for deviant voting patterns

## Prerequisites

- Node.js 18+
- Hardhat
- MetaMask wallet with Sepolia ETH

## Setup

```bash
npm install
npx hardhat compile
```

## Deployment

```bash
# Configure .env with your private key and RPC
cp .env.example .env

# Deploy all contracts
npx hardhat run scripts/deploy.js --network sepolia
```

## Usage

### Dashboard

Open `public/dashboard.html` in a browser and connect MetaMask to interact with deployed contracts.

### Contract Interactions

```bash
# Deposit to vault
npx hardhat run scripts/deposit.js --network sepolia

# Create proposal
npx hardhat run scripts/createProposal.js --network sepolia

# Cast vote
npx hardhat run scripts/castVote.js --network sepolia
```

## Contract Addresses (Sepolia)

| Contract | Address |
|----------|---------|
| LiquidDelegationVault | [DEPLOYED_ADDRESS] |
| GovernanceProposal | [DEPLOYED_ADDRESS] |
| ReputationOracle | [DEPLOYED_ADDRESS] |

## Testing

```bash
npx hardhat test
```

## Security

- Slashing triggers at 50% voting deviation
- 10% stake slashed per violation
- No ZK proofs - on-chain consensus detection

## License

MIT