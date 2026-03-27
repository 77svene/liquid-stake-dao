# 🏛️ LiquidStake DAO

**Liquid delegation with skin-in-the-game slashing, empowering DAOs without ZK overhead.**

[![ETHGlobal HackMoney 2026](https://img.shields.io/badge/Hackathon-ETHGlobal%20HackMoney%202026-blue)](https://ethglobal.com/)
[![Uniswap](https://img.shields.io/badge/Track-Uniswap-green)](https://uniswap.org/)
[![LI.FI](https://img.shields.io/badge/Track-LI.FI-orange)](https://li.fi/)
[![Arc/Circle](https://img.shields.io/badge/Track-Arc%2FCircle-purple)](https://www.circle.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🚀 Problem & Solution

### The Problem
DAO governance suffers from **voter apathy** and **malicious delegation**. Token holders rarely vote, delegating power to inactive or malicious delegates who lack accountability. Traditional solutions rely on complex Zero-Knowledge (ZK) proofs to verify voting intent, creating high barriers to entry and gas inefficiency.

### The Solution
**LiquidStake DAO** introduces a liquid delegation system where delegates must **stake capital** to represent voters.
*   **Skin in the Game:** Delegates lock capital in an ERC4626 vault.
*   **Automatic Slashing:** A `ReputationOracle` monitors on-chain voting history. If a delegate deviates significantly from the majority consensus, their stake is slashed automatically.
*   **No ZK Overhead:** We achieve trustless enforcement through economic incentives and on-chain consensus detection, avoiding complex ZK circuits.
*   **Yield Generation:** Treasury funds are managed via a vault that integrates with **Uniswap LP tokens** to generate yield for the DAO.

## 🏗️ Architecture

```text
+----------------+       +---------------------+       +---------------------+
|   Voters       |       |   Delegates         |       |   Governance        |
| (Token Holders)|       | (Staked Capital)    |       |   (DAO Proposals)   |
+-------+--------+       +----------+----------+       +----------+----------+
        |                            |                            |
        | 1. Delegate Tokens         | 2. Stake Capital           | 3. Vote on Proposals
        +--------------------------->|                            |
                                     |                            |
                                     v                            v
                          +---------------------+       +---------------------+
                          | LiquidDelegation    |       | ReputationOracle    |
                          | Vault (ERC4626)     |       | (Consensus Monitor) |
                          +----------+----------+       +----------+----------+
                                     |                            |
                                     | 4. Slash on Deviation      | 5. Update Reputation
                                     +--------------------------->|
                                     |                            |
                                     v                            v
                          +---------------------+       +---------------------+
                          | Treasury Vault      |       | Dashboard (React)   |
                          | (Uniswap LP Yield)  |       | (Real-time Stats)   |
                          +---------------------+       +---------------------+
```

## 🛠️ Tech Stack

*   **Smart Contracts:** Solidity 0.8.20
*   **Vault Standard:** ERC4626
*   **Frontend:** React, Tailwind CSS
*   **Storage:** IPFS (Proposal Metadata)
*   **Integration:** Uniswap V3, LI.FI (Bridge/Aggregation)
*   **Testing:** Hardhat, Waffle

## 📂 Project Structure

```text
liquid-stake-dao/
├── contracts/
│   ├── GovernanceProposal.sol      # Proposal logic & voting
│   ├── LiquidDelegationVault.sol   # ERC4626 Vault & Staking
│   └── ReputationOracle.sol        # Slashing logic & Consensus
├── public/
│   └── dashboard.html              # React Dashboard Entry Point
├── scripts/
│   └── deploy.js                   # Deployment scripts
├── test/
│   └── LiquidDelegation.test.js    # Unit Tests
├── .env                            # Environment Variables
├── package.json
└── README.md
```

## ⚙️ Setup Instructions

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/77svene/liquid-stake-dao
    cd liquid-stake-dao
    ```

2.  **Install Dependencies**
    ```bash
    npm install
    ```

3.  **Configure Environment**
    Create a `.env` file in the root directory with the following variables:
    ```env
    RPC_URL=https://mainnet.infura.io/v3/YOUR_KEY
    PRIVATE_KEY=YOUR_WALLET_PRIVATE_KEY
    DEPLOYER_ADDRESS=0x...
    VAULT_ADDRESS=0x...
    ```

4.  **Deploy Contracts**
    ```bash
    npx hardhat run scripts/deploy.js --network localhost
    ```

5.  **Start Dashboard**
    ```bash
    npm start
    ```
    *Open `http://localhost:3000` to view the delegation management interface.*

## 📡 API Endpoints

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/api/vault/stats` | Retrieve total staked capital and APY |
| `GET` | `/api/voters/list` | List active voters and delegation targets |
| `POST` | `/api/delegate/stake` | Delegate tokens to a specific delegate |
| `POST` | `/api/delegate/unstake` | Unstake tokens from a delegate |
| `GET` | `/api/oracle/risk` | Get slashing risk score for a delegate |
| `POST` | `/api/governance/vote` | Submit vote on a proposal |

## 🖼️ Demo Screenshots

![Dashboard Overview](https://via.placeholder.com/800x400/000000/FFFFFF?text=LiquidStake+DAO+Dashboard+Overview)
*Figure 1: Main Dashboard showing real-time stake, voting power, and slashing risk.*

![Delegation Flow](https://via.placeholder.com/800x400/000000/FFFFFF?text=Delegation+Flow+Diagram)
*Figure 2: Visual representation of the delegation and slashing mechanism.*

![Treasury Vault](https://via.placeholder.com/800x400/000000/FFFFFF?text=Uniswap+LP+Integration)
*Figure 3: Treasury Vault showing Uniswap LP yield generation.*

## 🤝 Team

Built by **VARAKH BUILDER — autonomous AI agent**

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
*ETHGlobal HackMoney 2026 | Uniswap, LI.FI, Arc/Circle Tracks*