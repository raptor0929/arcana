// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IInvestStrategy} from "./interfaces/IInvestStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaMorpho} from "./interfaces/IMetaMorpho.sol";

/**
 * @title MorphoStrategy
 * @dev Simple strategy that invests assets into Morpho MetaMorpho vaults
 */
contract MorphoStrategy is IInvestStrategy {

    // Simple storage
    IMetaMorpho public morphoVault;
    uint256 public shares;
    bool public initialized;
    IERC20 public assetToken;

    // Events
    event StrategyConnected(address indexed morphoVault);
    event StrategyDisconnected(bool force);
    event AssetsDeposited(uint256 assets, uint256 shares);
    event AssetsWithdrawn(uint256 assets, uint256 shares);

    /* -------------------------------------------------------------------------- */
    /*                            IInvestStrategy Implementation                   */
    /* -------------------------------------------------------------------------- */

    constructor(IERC20 asset_, IMetaMorpho morphoVault_) {
        assetToken = asset_;
        morphoVault = morphoVault_;

        assetToken.approve(address(morphoVault), type(uint256).max);
    }

    function connect(bytes memory initData) external override {
        require(!initialized, "Already initialized");
        shares = 0;
        initialized = true;
        emit StrategyConnected(address(morphoVault));
    }

    function disconnect(bool force) external override {
        require(initialized, "Not initialized");

        if (!force) {
            require(shares == 0, "Still has assets");
        }

        initialized = false;
        emit StrategyDisconnected(force);
    }

    function deposit(uint256 assets) external override {
        require(initialized, "Not initialized");
        require(assets > 0, "Zero assets");

        // Deposit into Morpho vault
        uint256 newShares = morphoVault.deposit(assets, address(this));
        shares += newShares;

        emit AssetsDeposited(assets, newShares);
    }

    function withdraw(uint256 assets) external override {
        require(initialized, "Not initialized");
        require(assets > 0, "Zero assets");

        // Calculate shares needed for the requested assets
        uint256 sharesNeeded = morphoVault.previewWithdraw(assets);
        require(sharesNeeded <= shares, "Insufficient shares");

        // Withdraw from Morpho vault to the calling vault
        uint256 sharesWithdrawn = morphoVault.withdraw(assets, msg.sender, address(this));
        shares -= sharesWithdrawn;

        emit AssetsWithdrawn(assets, sharesWithdrawn);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 View Functions                              */
    /* -------------------------------------------------------------------------- */

    function asset(address) external view override returns (address) {
        require(initialized, "Not initialized");
        return morphoVault.asset();
    }

    function totalAssets(address) external view override returns (uint256) {
        if (!initialized || shares == 0) {
            return 0;
        }
        return morphoVault.previewRedeem(shares);
    }

    function maxDeposit(address contract_) external view override returns (uint256) {
        return IERC20(address(contract_)).balanceOf(contract_);
    }

    function maxWithdraw(address) external view override returns (uint256) {
        if (!initialized || shares == 0) {
            return 0;
        }
        return morphoVault.previewRedeem(shares);
    }

    function storageSlot() external pure override returns (bytes32) {
        return keccak256("morpho.strategy.storage");
    }
}
