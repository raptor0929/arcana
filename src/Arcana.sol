// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IInvestStrategy} from "./interfaces/IInvestStrategy.sol";

/**
 * @title Arcana
 * @dev Simple ERC4626 vault that can plug into multiple strategies.
 *      Assets are allocated to strategies and can be rebalanced.
 */
contract Arcana is ERC4626, Ownable {

    struct StrategyInfo {
        IInvestStrategy strategy;
        bool active;
    }

    StrategyInfo[] public strategies;

    constructor(IERC20 asset_, string memory name_, string memory symbol_)
        ERC4626(asset_)
        ERC20(name_, symbol_)
        Ownable(msg.sender)
    {}

    /* -------------------------------------------------------------------------- */
    /*                               Strategy Mgmt                                */
    /* -------------------------------------------------------------------------- */

    function addStrategy(address strategy, bytes calldata initData) external onlyOwner {
        IInvestStrategy(strategy).connect(initData);
        strategies.push(StrategyInfo(IInvestStrategy(strategy), true));
        IERC20(asset()).approve(strategy, type(uint256).max);
    }

    function removeStrategy(uint256 index, bool force) external onlyOwner {
        StrategyInfo storage s = strategies[index];
        s.strategy.disconnect(force);
        s.active = false;
        IERC20(asset()).approve(address(s.strategy), 0);
    }

    function numStrategies() external view returns (uint256) {
        return strategies.length;
    }

    /* -------------------------------------------------------------------------- */
    /*                        ERC4626 Hooks - Deposit/Withdraw                     */
    /* -------------------------------------------------------------------------- */

    /// @dev override deposit hook to push assets into first active strategy
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal override {
        super._deposit(caller, receiver, assets, shares);

        // Pick the first active strategy for now
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategies[i].active) {
                // Funds are already inside the vault (this)
                IERC20(asset()).transfer(address(strategies[i].strategy), assets);
                strategies[i].strategy.deposit(assets);
                break;
            }
        }
    }

    /// @dev override withdraw hook to pull assets from strategies if needed
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));

        if (vaultBalance < assets) {
            uint256 needed = assets - vaultBalance;
            // Pull proportionally from active strategies until satisfied
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

    function rebalance(uint256 fromIdx, uint256 toIdx, uint256 assets) external onlyOwner {
        require(fromIdx < strategies.length && toIdx < strategies.length, "invalid index");
        require(strategies[fromIdx].active && strategies[toIdx].active, "inactive");

        // Withdraw from one strategy
        strategies[fromIdx].strategy.withdraw(assets);

        // Transfer tokens to the target strategy
        IERC20(asset()).transfer(address(strategies[toIdx].strategy), assets);

        // Deposit into another strategy
        strategies[toIdx].strategy.deposit(assets);
    }

    /* -------------------------------------------------------------------------- */
    /*                             Accounting Override                             */
    /* -------------------------------------------------------------------------- */

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
