// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IInvestStrategy} from "./interfaces/IInvestStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaMorpho} from "./interfaces/IMetaMorpho.sol";

/**
 * @title MorphoStrategy
 * @dev Investment strategy that allocates assets into Morpho MetaMorpho vaults.
 *      Provides yield generation through Morpho's lending protocol while maintaining
 *      ERC4626 compatibility for integration with the Arcana vault.
 */
contract MorphoStrategy is IInvestStrategy {

    /// @dev The Morpho MetaMorpho vault to deposit assets into
    IMetaMorpho public morphoVault;
    
    /// @dev Current number of shares held in the Morpho vault
    uint256 public shares;
    
    /// @dev Whether the strategy has been initialized
    bool public initialized;
    
    /// @dev The underlying asset token (e.g., USDC, DAI)
    IERC20 public assetToken;

    // Events
    event StrategyConnected(address indexed morphoVault);
    event StrategyDisconnected(bool force);
    event AssetsDeposited(uint256 assets, uint256 shares);
    event AssetsWithdrawn(uint256 assets, uint256 shares);

    /* -------------------------------------------------------------------------- */
    /*                            IInvestStrategy Implementation                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Constructor to initialize the strategy with asset and vault addresses
     * @param asset_ The underlying asset token
     * @param morphoVault_ The Morpho MetaMorpho vault to use
     */
    constructor(IERC20 asset_, IMetaMorpho morphoVault_) {
        assetToken = asset_;
        morphoVault = morphoVault_;

        // Approve the Morpho vault to spend the asset token
        assetToken.approve(address(morphoVault), type(uint256).max);
    }

    /**
     * @dev Initializes the strategy with optional configuration data
     * @param initData Initialization data (unused in this implementation)
     * 
     * Requirements:
     * - Strategy must not already be initialized
     */
    function connect(bytes memory initData) external override {
        require(!initialized, "Already initialized");
        shares = 0;
        initialized = true;
        emit StrategyConnected(address(morphoVault));
    }

    /**
     * @dev Disconnects the strategy, optionally forcing withdrawal of all assets
     * @param force If true, forces disconnection even if strategy has assets
     * 
     * Requirements:
     * - Strategy must be initialized
     * - If not forcing, strategy must have no assets
     */
    function disconnect(bool force) external override {
        require(initialized, "Not initialized");

        if (!force) {
            require(shares == 0, "Still has assets");
        }

        initialized = false;
        emit StrategyDisconnected(force);
    }

    /**
     * @dev Deposits assets into the Morpho vault
     * @param assets Amount of assets to deposit
     * 
     * Requirements:
     * - Strategy must be initialized
     * - Assets amount must be greater than zero
     */
    function deposit(uint256 assets) external override {
        require(initialized, "Not initialized");
        require(assets > 0, "Zero assets");

        // Deposit into Morpho vault and track shares
        uint256 newShares = morphoVault.deposit(assets, address(this));
        shares += newShares;

        emit AssetsDeposited(assets, newShares);
    }

    /**
     * @dev Withdraws assets from the Morpho vault
     * @param assets Amount of assets to withdraw
     * 
     * Requirements:
     * - Strategy must be initialized
     * - Assets amount must be greater than zero
     * - Strategy must have sufficient shares for the withdrawal
     */
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

    /**
     * @dev Returns the address of the underlying asset token
     * @return Address of the asset token
     * 
     * Requirements:
     * - Strategy must be initialized
     */
    function asset(address) external view override returns (address) {
        require(initialized, "Not initialized");
        return morphoVault.asset();
    }

    /**
     * @dev Returns the total assets managed by this strategy
     * @return Total assets value in the underlying asset token
     */
    function totalAssets(address) external view override returns (uint256) {
        if (!initialized || shares == 0) {
            return 0;
        }
        return morphoVault.previewRedeem(shares);
    }

    /**
     * @dev Returns the maximum amount that can be deposited
     * @param contract_ Address of the contract requesting the deposit
     * @return Maximum amount that can be deposited
     */
    function maxDeposit(address contract_) external view override returns (uint256) {
        return IERC20(address(contract_)).balanceOf(contract_);
    }

    /**
     * @dev Returns the maximum amount that can be withdrawn
     * @return Maximum amount that can be withdrawn
     */
    function maxWithdraw(address) external view override returns (uint256) {
        if (!initialized || shares == 0) {
            return 0;
        }
        return morphoVault.previewRedeem(shares);
    }

    /**
     * @dev Returns a unique storage slot identifier for this strategy
     * @return Unique bytes32 identifier
     */
    function storageSlot() external pure override returns (bytes32) {
        return keccak256("morpho.strategy.storage");
    }
}
