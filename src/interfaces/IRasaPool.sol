// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IRasaPool {
    // Supply assets to the lending pool and mint RS tokens
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    // Withdraw assets from the lending pool by burning RS tokens
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    // Get comprehensive data about a reserve including rates, tokens, and balances
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