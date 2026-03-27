const hre = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Deploying LiquidStake DAO to Sepolia...");
  
  const [deployer] = await hre.ethers.getSigners();
  console.log("📍 Deploying from:", deployer.address);
  
  const alchemyApiKey = process.env.ALCHEMY_API_KEY || "";
  const etherscanApiKey = process.env.ETHERSCAN_API_KEY || "";
  
  if (!alchemyApiKey) {
    console.error("❌ Missing ALCHEMY_API_KEY environment variable");
    process.exit(1);
  }
  
  if (!etherscanApiKey) {
    console.error("❌ Missing ETHERSCAN_API_KEY environment variable");
    process.exit(1);
  }
  
  try {
    // Deploy LiquidDelegationVault first
    console.log("\n📦 Deploying LiquidDelegationVault...");
    const VaultFactory = await hre.ethers.getContractFactory("LiquidDelegationVault");
    const vault = await VaultFactory.deploy(
      "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14", // WETH on Sepolia
      "LiquidStake",
      "LST"
    );
    await vault.waitForDeployment();
    const vaultAddress = await vault.getAddress();
    console.log("✅ LiquidDelegationVault deployed at:", vaultAddress);
    
    // Deploy GovernanceProposal
    console.log("\n📦 Deploying GovernanceProposal...");
    const GovernanceFactory = await hre.ethers.getContractFactory("GovernanceProposal");
    const governance = await GovernanceFactory.deploy(vaultAddress);
    await governance.waitForDeployment();
    const governanceAddress = await governance.getAddress();
    console.log("✅ GovernanceProposal deployed at:", governanceAddress);
    
    // Deploy ReputationOracle
    console.log("\n📦 Deploying ReputationOracle...");
    const OracleFactory = await hre.ethers.getContractFactory("ReputationOracle");
    const oracle = await OracleFactory.deploy(vaultAddress, governanceAddress);
    await oracle.waitForDeployment();
    const oracleAddress = await oracle.getAddress();
    console.log("✅ ReputationOracle deployed at:", oracleAddress);
    
    // Set up inter-contract relationships
    console.log("\n🔗 Setting up inter-contract relationships...");
    await governance.setVault(vaultAddress);
    console.log("✅ GovernanceProposal vault set to:", vaultAddress);
    
    // Verify contracts on Etherscan
    console.log("\n🔍 Verifying contracts on Etherscan...");
    const verificationResults = {};
    
    try {
      await hre.run("verify:verify", {
        address: vaultAddress,
        constructorArguments: ["0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14", "LiquidStake", "LST"]
      });
      verificationResults.vault = "SUCCESS";
      console.log("✅ LiquidDelegationVault verified on Etherscan");
    } catch (e) {
      verificationResults.vault = e.message.includes("already verified") ? "ALREADY_VERIFIED" : "FAILED: " + e.message;
      console.log("⚠️  LiquidDelegationVault verification:", verificationResults.vault);
    }
    
    try {
      await hre.run("verify:verify", {
        address: governanceAddress,
        constructorArguments: [vaultAddress]
      });
      verificationResults.governance = "SUCCESS";
      console.log("✅ GovernanceProposal verified on Etherscan");
    } catch (e) {
      verificationResults.governance = e.message.includes("already verified") ? "ALREADY_VERIFIED" : "FAILED: " + e.message;
      console.log("⚠️  GovernanceProposal verification:", verificationResults.governance);
    }
    
    try {
      await hre.run("verify:verify", {
        address: oracleAddress,
        constructorArguments: [vaultAddress, governanceAddress]
      });
      verificationResults.oracle = "SUCCESS";
      console.log("✅ ReputationOracle verified on Etherscan");
    } catch (e) {
      verificationResults.oracle = e.message.includes("already verified") ? "ALREADY_VERIFIED" : "FAILED: " + e.message;
      console.log("⚠️  ReputationOracle verification:", verificationResults.oracle);
    }
    
    // Save deployment info
    const deploymentInfo = {
      network: hre.network.name,
      deployer: deployer.address,
      contracts: {
        vault: vaultAddress,
        governance: governanceAddress,
        oracle: oracleAddress
      },
      verification: verificationResults,
      timestamp: new Date().toISOString()
    };
    
    fs.writeFileSync(
      "deployment-info.json",
      JSON.stringify(deploymentInfo, null, 2)
    );
    console.log("\n💾 Deployment info saved to deployment-info.json");
    
    // Print summary
    console.log("\n" + "=".repeat(60));
    console.log("🎉 DEPLOYMENT COMPLETE");
    console.log("=".repeat(60));
    console.log("Network:", hre.network.name);
    console.log("Deployer:", deployer.address);
    console.log("Vault:", vaultAddress);
    console.log("Governance:", governanceAddress);
    console.log("Oracle:", oracleAddress);
    console.log("=".repeat(60));
    
  } catch (error) {
    console.error("\n❌ Deployment failed:", error.message);
    process.exit(1);
  }
}

main().then(() => process.exit(0)).catch((error) => {
  console.error(error);
  process.exit(1);
});