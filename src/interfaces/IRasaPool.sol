// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IRasaPool
 * @dev Interface for Rasa lending pools, which provide lending and borrowing
 *      functionality with yield generation through interest rates and protocol fees.
 */
interface IRasaPool {
    /**
     * @dev Supplies assets to the lending pool and mints RS tokens
     * @param asset The asset to supply
     * @param amount Amount of assets to supply
     * @param onBehalfOf Address to receive the RS tokens
     * @param referralCode Referral code for tracking
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    
    /**
     * @dev Withdraws assets from the lending pool by burning RS tokens
     * @param asset The asset to withdraw
     * @param amount Amount of assets to withdraw
     * @param to Address to receive the withdrawn assets
     * @return Amount of assets withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    
    /**
     * @dev Returns comprehensive data about a reserve including rates, tokens, and balances
     * @param asset The asset to get reserve data for
     * @return configuration Reserve configuration flags
     * @return liquidityIndex The liquidity index, expressed in ray
     * @return currentLiquidityRate The current supply rate, expressed in ray
     * @return variableBorrowIndex Variable borrow index, expressed in ray
     * @return currentVariableBorrowRate The current variable borrow rate, expressed in ray
     * @return currentStableBorrowRate The current stable borrow rate, expressed in ray
     * @return lastUpdateTimestamp Timestamp of last update
     * @return id The ID of the reserve, representing position in active reserves list
     * @return RSTokenAddress Address of the RS token for this reserve
     * @return stableDebtTokenAddress Address of the stable debt token
     * @return variableDebtTokenAddress Address of the variable debt token
     * @return interestRateStrategyAddress Address of the interest rate strategy
     * @return accruedToTreasury The current treasury balance, scaled
     * @return unbacked The outstanding unbacked RS tokens minted through bridging
     * @return isolationModeTotalDebt The outstanding debt borrowed against this asset in isolation mode
     */
    function getReserveData(address asset) external view returns (
        uint256 configuration,
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex,
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate,
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex,
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate,
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate,
        //timestamp of last update
        uint40 lastUpdateTimestamp,
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id,
        //RSToken address
        address RSTokenAddress,
        //stableDebtToken address
        address stableDebtTokenAddress,
        //variableDebtToken address
        address variableDebtTokenAddress,
        //address of the interest rate strategy
        address interestRateStrategyAddress,
        //the current treasury balance, scaled
        uint128 accruedToTreasury,
        //the outstanding unbacked RSTokens minted through the bridging feature
        uint128 unbacked,
        //the outstanding debt borrowed against this asset in isolation mode
        uint128 isolationModeTotalDebt
    );
}