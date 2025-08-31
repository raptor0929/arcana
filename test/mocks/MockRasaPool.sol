// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRasaPool} from "../../src/interfaces/IRasaPool.sol";
import {MockToken} from "./MockToken.sol";

/**
 * @title MockRasaPool
 * @dev Mock implementation of Rasa lending pool for testing purposes.
 *      Provides simplified lending functionality with 1:1 asset-to-aToken ratio.
 */
contract MockRasaPool is IRasaPool {
    /// @dev The underlying asset token (e.g., USDC, DAI)
    IERC20 public immutable asset;
    
    /// @dev Mapping of user addresses to their aToken balances
    mapping(address => uint256) public aTokenBalances;
    
    /// @dev Total aTokens minted across all users
    uint256 public totalATokens;
    
    /// @dev Mock aToken contract representing the lending position
    MockToken public immutable aToken;

    /**
     * @dev Constructor to initialize the mock pool with an asset token
     * @param _asset The ERC20 token to be used as the underlying asset
     */
    constructor(IERC20 _asset) {
        asset = _asset;
        aToken = new MockToken("Rasa AToken", "RASA");
        aToken.mint(address(this), 1000000e6);
    }

    /**
     * @dev Supplies assets to the lending pool and mints aTokens
     * @param _asset The asset to supply (must match the pool's asset)
     * @param amount Amount of assets to supply
     * @param onBehalfOf Address to receive the aTokens
     * @param referralCode Referral code (unused in mock)
     */
    function supply(address _asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        require(_asset == address(asset), "Wrong asset");
        require(amount > 0, "Zero amount");
        
        // Simple 1:1 ratio for testing
        aTokenBalances[onBehalfOf] += amount;
        totalATokens += amount;
        
        // Mint aTokens to the strategy
        aToken.mint(onBehalfOf, amount);
        
        // Transfer assets from caller
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    /**
     * @dev Withdraws assets from the lending pool by burning aTokens
     * @param _asset The asset to withdraw (must match the pool's asset)
     * @param amount Amount of assets to withdraw
     * @param to Address to receive the withdrawn assets
     * @return Amount of assets withdrawn
     */
    function withdraw(address _asset, uint256 amount, address to) external returns (uint256) {
        require(_asset == address(asset), "Wrong asset");
        require(amount > 0, "Zero amount");
        require(aTokenBalances[msg.sender] >= amount, "Insufficient balance");
        
        aTokenBalances[msg.sender] -= amount;
        totalATokens -= amount;
        
        // Burn aTokens from the strategy
        aToken.burn(msg.sender, amount);
        
        // Transfer assets to recipient
        IERC20(asset).transfer(to, amount);
        return amount;
    }

    /**
     * @dev Returns comprehensive reserve data for the specified asset
     * @param _asset The asset to get reserve data for
     * @return configuration Reserve configuration flags
     * @return liquidityIndex Current liquidity index
     * @return variableBorrowIndex Current variable borrow index
     * @return currentLiquidityRate Current liquidity rate
     * @return currentVariableBorrowRate Current variable borrow rate
     * @return currentStableBorrowRate Current stable borrow rate
     * @return lastUpdateTimestamp Timestamp of last update
     * @return id Reserve ID
     * @return aTokenAddress Address of the aToken contract
     * @return stableDebtTokenAddress Address of stable debt token (unused)
     * @return variableDebtTokenAddress Address of variable debt token (unused)
     * @return interestRateStrategyAddress Address of interest rate strategy (unused)
     * @return accruedToTreasury Treasury balance
     * @return unbacked Unbacked tokens
     * @return isolationModeTotalDebt Isolation mode total debt
     */
    function getReserveData(address _asset) external view returns (
        uint256 configuration,
        uint128 liquidityIndex,
        uint128 variableBorrowIndex,
        uint128 currentLiquidityRate,
        uint128 currentVariableBorrowRate,
        uint128 currentStableBorrowRate,
        uint40 lastUpdateTimestamp,
        uint16 id,
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress,
        address interestRateStrategyAddress,
        uint128 accruedToTreasury,
        uint128 unbacked,
        uint128 isolationModeTotalDebt
    ) {
        require(_asset == address(asset), "Wrong asset");
        
        // Return mock data - aTokenAddress is the aToken contract
        return (
            1, // configuration (active)
            1e27, // liquidityIndex
            1e27, // variableBorrowIndex
            0, // currentLiquidityRate
            0, // currentVariableBorrowRate
            0, // currentStableBorrowRate
            uint40(block.timestamp), // lastUpdateTimestamp
            0, // id
            address(aToken), // aTokenAddress (the aToken contract)
            address(0), // stableDebtTokenAddress
            address(0), // variableDebtTokenAddress
            address(0), // interestRateStrategyAddress
            0, // accruedToTreasury
            0, // unbacked
            0 // isolationModeTotalDebt
        );
    }
}
