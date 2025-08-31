// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IInvestStrategy} from "./interfaces/IInvestStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRasaPool} from "./interfaces/IRasaPool.sol";

/**
 * @title RasaStrategy
 * @dev Investment strategy that allocates assets into Rasa lending pools.
 *      Provides yield generation through Rasa's lending protocol while maintaining
 *      ERC4626 compatibility for integration with the Arcana vault.
 */
contract RasaStrategy is IInvestStrategy {

    /// @dev The Rasa lending pool to supply assets to
    IRasaPool public immutable rasaPool;
    
    /// @dev The underlying asset token (e.g., USDC, DAI)
    IERC20 public immutable assetToken;
    
    /// @dev The Rasa RS token representing the lending position
    address public immutable rsToken;

    // Events
    event StrategyConnected();
    event StrategyDisconnected(bool force);
    event AssetsSupplied(uint256 assets);
    event AssetsWithdrawn(uint256 assets);

    /**
     * @dev Constructor to initialize the strategy with asset and pool addresses
     * @param asset_ The underlying asset token
     * @param rasaPool_ The Rasa lending pool to use
     * 
     * Requirements:
     * - Reserve must exist in the Rasa pool for the specified asset
     */
    constructor(IERC20 asset_, IRasaPool rasaPool_) {
        assetToken = asset_;
        rasaPool = rasaPool_;
        
        // Get RS token address from Rasa pool reserve data
        (,,,,,,,, address rsTokenAddress,,,,,,) = rasaPool.getReserveData(address(asset_));
        require(rsTokenAddress != address(0), "Reserve not found");
        rsToken = rsTokenAddress;

        // Approve the Rasa pool to spend the asset token
        assetToken.approve(address(rasaPool), type(uint256).max);
    }

    /**
     * @dev Initializes the strategy with optional configuration data
     * @param initData Initialization data (must be empty for this implementation)
     * 
     * Requirements:
     * - Init data must be empty
     */
    function connect(bytes memory initData) external override {
        require(initData.length == 0, "No extra data allowed");
        emit StrategyConnected();
    }

    /**
     * @dev Disconnects the strategy, optionally forcing withdrawal of all assets
     * @param force If true, forces disconnection even if strategy has assets
     * 
     * Requirements:
     * - If not forcing, strategy must have no RS tokens
     */
    function disconnect(bool force) external override {
        if (!force) {
            require(IERC20(rsToken).balanceOf(address(this)) == 0, "Still has assets");
        }
        emit StrategyDisconnected(force);
    }

    /**
     * @dev Deposits assets into the Rasa lending pool
     * @param assets Amount of assets to deposit
     * 
     * Requirements:
     * - Assets amount must be greater than zero
     */
    function deposit(uint256 assets) external override {
        if (assets > 0) {
            _supply(assets);
        }
    }

    /**
     * @dev Withdraws assets from the Rasa lending pool
     * @param assets Amount of assets to withdraw
     * 
     * Requirements:
     * - Assets amount must be greater than zero
     * - Strategy must have sufficient RS tokens for the withdrawal
     */
    function withdraw(uint256 assets) external override {
        uint256 rsTokenBalance = IERC20(rsToken).balanceOf(address(this));
        if (assets > 0) {
            require(rsTokenBalance >= assets, "Insufficient balance");
            rasaPool.withdraw(address(assetToken), assets, msg.sender);
            emit AssetsWithdrawn(assets);
        }
    }

    /**
     * @dev Internal function to supply assets to the Rasa pool
     * @param assets Amount of assets to supply
     */
    function _supply(uint256 assets) internal {
        rasaPool.supply(address(assetToken), assets, address(this), 0);
        emit AssetsSupplied(assets);
    }

    /**
     * @dev Returns the address of the underlying asset token
     * @return Address of the asset token
     */
    function asset(address) external view override returns (address) {
        return address(assetToken);
    }

    /**
     * @dev Returns the total assets managed by this strategy
     * @return Total assets value in the underlying asset token
     */
    function totalAssets(address) external view override returns (uint256) {
        return IERC20(rsToken).balanceOf(address(this));
    }

    /**
     * @dev Returns the maximum amount that can be deposited
     * @return Maximum amount that can be deposited (unlimited)
     */
    function maxDeposit(address) external pure override returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @dev Returns the maximum amount that can be withdrawn
     * @return Maximum amount that can be withdrawn
     */
    function maxWithdraw(address) external view override returns (uint256) {
        return IERC20(rsToken).balanceOf(address(this));
    }

    /**
     * @dev Returns a unique storage slot identifier for this strategy
     * @return Unique bytes32 identifier
     */
    function storageSlot() external pure override returns (bytes32) {
        return keccak256("rasa.strategy.storage");
    }
}
