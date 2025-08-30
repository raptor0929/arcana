# 🏛️ Arcana Vault

**A sophisticated ERC4626 vault with pluggable investment strategies for DeFi yield optimization**

Arcana is a yield aggregator that allows users to deposit assets and automatically deploy them across multiple DeFi protocols through a unified interface. Built with security, efficiency, and composability in mind.

## 🎯 Use Cases

- **Yield Farming**: Automatically deploy capital across multiple yield-generating protocols
- **Risk Management**: Diversify exposure across different DeFi strategies
- **Capital Efficiency**: Optimize returns through intelligent rebalancing
- **Simplified DeFi**: Single interface for multiple protocol interactions
- **Institutional DeFi**: Professional-grade vault for large capital deployment

## 🚀 Key Features

### ✨ ERC4626 Compliance
- Standard tokenized vault interface
- Seamless integration with DeFi protocols
- Predictable share calculation and redemption

### 🔌 Pluggable Strategies
- **MorphoStrategy**: Integration with Morpho MetaMorpho vaults
- **RasaStrategy**: Integration with Aave-like lending pools
- Easy to add new strategies through the `IInvestStrategy` interface

### ⚖️ Dynamic Rebalancing
- Move assets between strategies based on market conditions
- Optimize for highest yields across protocols
- Maintain risk-adjusted returns

### 🛡️ Security Features
- Owner-controlled strategy management
- Emergency withdrawal capabilities
- Comprehensive testing suite

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Assets   │───▶│  Arcana Vault   │───▶│   Strategies    │
│                 │    │   (ERC4626)     │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │  Rebalancing    │    │  Yield Sources  │
                       │   Engine        │    │                 │
                       └─────────────────┘    └─────────────────┘
```

## 📊 Strategy Details

### 🦋 MorphoStrategy
- **Protocol**: Morpho MetaMorpho vaults
- **Yield Source**: Lending and borrowing optimization
- **Risk Profile**: Medium (diversified lending positions)
- **Key Features**: 
  - Automated position management
  - Gas-efficient operations
  - Real-time yield optimization

### 🌊 RasaStrategy  
- **Protocol**: Aave-like lending pools
- **Yield Source**: Supply-side lending rewards
- **Risk Profile**: Low (collateralized lending)
- **Key Features**:
  - Stable lending yields
  - Liquid collateral
  - Proven protocol security

## 🛠️ Development

### Prerequisites
- Foundry (latest version)
- Node.js 16+
- Git

### Installation
```bash
git clone <repository-url>
cd arcana
forge install
```

### Build
```bash
forge build
```

### Test
```bash
# Run all tests
forge test

# Run specific test file
forge test --match-contract ArcanaTest

# Run with verbose output
forge test -vvv
```

### Deploy
```bash
# Deploy to mainnet
forge script script/Arcana.s.sol:ArcanaScript --rpc-url <your_rpc_url> --private-key <your_private_key> --broadcast --verify

# Deploy to testnet
forge script script/Arcana.s.sol:ArcanaScript --rpc-url <testnet_rpc_url> --private-key <your_private_key> --broadcast
```

## 📈 Usage Examples

### Basic Deposit
```solidity
// Approve tokens
asset.approve(address(arcana), amount);

// Deposit and receive vault shares
uint256 shares = arcana.deposit(amount, receiver);
```

### Strategy Rebalancing
```solidity
// Move 1000 tokens from Morpho (index 0) to Rasa (index 1)
arcana.rebalance(0, 1, 1000);
```

### Withdrawal
```solidity
// Withdraw assets by burning shares
uint256 assets = arcana.withdraw(shares, receiver, owner);
```

## 🔍 Testing

The project includes comprehensive tests covering:

- ✅ Vault deposit/withdraw functionality
- ✅ Strategy integration (Morpho & Rasa)
- ✅ Rebalancing operations
- ✅ Edge cases and error conditions
- ✅ Mock contract interactions

### Test Structure
```
test/
├── Arcana.t.sol              # Unit tests for vault functionality
├── ArcanaIntegration.t.sol   # Integration tests with real protocols
└── mocks/
    ├── MockToken.sol         # ERC20 token for testing
    ├── MockMorphoVault.sol   # Morpho vault simulation
    └── MockRasaPool.sol      # Rasa pool simulation
```

## 🔧 Configuration

### Strategy Parameters
- **MorphoStrategy**: Requires Morpho vault address and asset token
- **RasaStrategy**: Requires Rasa pool address and asset token
- **Rebalancing**: Owner-controlled with configurable thresholds

### Gas Optimization
- Efficient batch operations
- Minimal external calls
- Optimized storage patterns

## 🚨 Security Considerations

- **Access Control**: Owner-only strategy management
- **Reentrancy Protection**: Standard OpenZeppelin patterns
- **Slippage Protection**: Configurable limits for large operations
- **Emergency Functions**: Quick withdrawal capabilities

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📞 Support

- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Documentation**: Inline code comments and this README

---

**Built with ❤️ for the DeFi community**
