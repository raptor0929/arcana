// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IInvestStrategy} from "./interfaces/IInvestStrategy.sol";

/**
 * @title Arcana
 * @dev ERC4626 vault that can dynamically allocate assets across multiple investment strategies.
 *      Users deposit assets and receive vault shares, while the vault distributes funds
 *      to underlying strategies for yield generation. Supports strategy rebalancing
 *      and dynamic strategy management.
 */
contract Arcana is ERC4626, Ownable {

    /// @dev Structure to track strategy information and status
    struct StrategyInfo {
        IInvestStrategy strategy; // The strategy contract
        bool active;              // Whether the strategy is currently active
    }

    /// @dev Array of all strategies added to the vault
    StrategyInfo[] public strategies;

    /**
     * @dev Constructor to initialize the vault with asset token and metadata
     * @param asset_ The underlying asset token (e.g., USDC, DAI)
     * @param name_ The name of the vault token
     * @param symbol_ The symbol of the vault token
     */
    constructor(IERC20 asset_, string memory name_, string memory symbol_)
        ERC4626(asset_)
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {}

    /* -------------------------------------------------------------------------- */
    /*                               Strategy Management                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Adds a new investment strategy to the vault
     * @param strategy Address of the strategy contract to add
     * @param initData Initialization data for the strategy
     * 
     * Requirements:
     * - Caller must be the vault owner
     * - Strategy must implement IInvestStrategy interface
     */
    function addStrategy(address strategy, bytes calldata initData) external onlyOwner {
        IInvestStrategy(strategy).connect(initData);
        strategies.push(StrategyInfo(IInvestStrategy(strategy), true));
        IERC20(asset()).approve(strategy, type(uint256).max);
    }

    /**
     * @dev Removes a strategy from the vault, optionally forcing withdrawal
     * @param index Index of the strategy to remove
     * @param force If true, forces withdrawal even if strategy has assets
     * 
     * Requirements:
     * - Caller must be the vault owner
     * - Index must be valid
     */
    function removeStrategy(uint256 index, bool force) external onlyOwner {
        StrategyInfo storage s = strategies[index];
        s.strategy.disconnect(force);
        s.active = false;
        IERC20(asset()).approve(address(s.strategy), 0);
    }

    /**
     * @dev Returns the total number of strategies in the vault
     * @return Number of strategies (both active and inactive)
     */
    function numStrategies() external view returns (uint256) {
        return strategies.length;
    }

    /* -------------------------------------------------------------------------- */
    /*                        ERC4626 Hooks - Deposit/Withdraw                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Override of ERC4626 deposit hook to allocate assets to strategies
     * @param caller Address initiating the deposit
     * @param receiver Address receiving the vault shares
     * @param assets Amount of assets being deposited
     * @param shares Amount of shares being minted
     * 
     * Allocates deposited assets to the first available active strategy.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);

        // Allocate to the first active strategy
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].active) {
                // Transfer assets from vault to strategy
                IERC20(asset()).transfer(address(strategies[i].strategy), assets);
                strategies[i].strategy.deposit(assets);
                break;
            }
        }
    }

    /**
     * @dev Override of ERC4626 withdraw hook to pull assets from strategies if needed
     * @param caller Address initiating the withdrawal
     * @param receiver Address receiving the withdrawn assets
     * @param owner Address whose shares are being burned
     * @param assets Amount of assets being withdrawn
     * @param shares Amount of shares being burned
     * 
     * If vault balance is insufficient, withdraws proportionally from active strategies.
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));

        if (vaultBalance < assets) {
            uint256 needed = assets - vaultBalance;
            // Withdraw proportionally from active strategies until satisfied
            for (uint256 i = 0; i < strategies.length && needed > 0; i++) {
                if (!strategies[i].active) continue;
                uint256 maxW = strategies[i].strategy.maxWithdraw(address(this));
                uint256 toWithdraw = needed > maxW ? maxW : needed;
                if (toWithdraw > 0) {
                    strategies[i].strategy.withdraw(toWithdraw);
                    needed -= toWithdraw;
                }
            }
        }

        super._withdraw(caller, receiver, owner, assets, shares);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Rebalancing                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Rebalances assets between two strategies
     * @param fromIdx Index of the strategy to withdraw from
     * @param toIdx Index of the strategy to deposit into
     * @param assets Amount of assets to rebalance
     * 
     * Requirements:
     * - Caller must be the vault owner
     * - Both strategy indices must be valid
     * - Both strategies must be active
     */
    function rebalance(uint256 fromIdx, uint256 toIdx, uint256 assets) external onlyOwner {
        require(fromIdx < strategies.length && toIdx < strategies.length, "Invalid index");
        require(strategies[fromIdx].active && strategies[toIdx].active, "Inactive strategy");

        // Withdraw from source strategy
        strategies[fromIdx].strategy.withdraw(assets);

        // Transfer tokens to target strategy
        IERC20(asset()).transfer(address(strategies[toIdx].strategy), assets);

        // Deposit into target strategy
        strategies[toIdx].strategy.deposit(assets);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Accounting Override                             */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Returns the total assets managed by the vault across all active strategies
     * @return Total assets including vault balance and strategy allocations
     */
    function totalAssets() public view override returns (uint256) {
        uint256 total = IERC20(asset()).balanceOf(address(this));
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].active) {
                total += strategies[i].strategy.totalAssets(address(this));
            }
        }
        return total;
    }
}
