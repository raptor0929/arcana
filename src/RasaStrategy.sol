// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IInvestStrategy} from "./interfaces/IInvestStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRasaPool} from "./interfaces/IRasaPool.sol";
import {console} from "forge-std/console.sol";

/**
 * @title RasaStrategy
 * @dev Simplified Rasa strategy
 */
contract RasaStrategy is IInvestStrategy {

    // Immutable storage
    IRasaPool public immutable rasaPool;
    IERC20 public immutable assetToken;
    address public immutable rsToken;

    // Events
    event StrategyConnected();
    event StrategyDisconnected(bool force);
    event AssetsSupplied(uint256 assets);
    event AssetsWithdrawn(uint256 assets);

    constructor(IERC20 asset_, IRasaPool rasaPool_) {
        assetToken = asset_;
        rasaPool = rasaPool_;
        
        // Get RS token address from Rasa
        (,,,,,,,, address rsTokenAddress,,,,,,) = rasaPool.getReserveData(address(asset_));
        require(rsTokenAddress != address(0), "Reserve not found");
        rsToken = rsTokenAddress;

        assetToken.approve(address(rasaPool), type(uint256).max);
    }

    function connect(bytes memory initData) external override {
        require(initData.length == 0, "No extra data allowed");
        emit StrategyConnected();
    }

    function disconnect(bool force) external override {
        if (!force) {
            require(IERC20(rsToken).balanceOf(address(this)) == 0, "Still has assets");
        }
        emit StrategyDisconnected(force);
    }

    function deposit(uint256 assets) external override {
        if (assets > 0) {
            _supply(assets);
        }
    }

    function withdraw(uint256 assets) external override {
        uint256 rsTokenBalance = IERC20(rsToken).balanceOf(address(this));
        if (assets > 0) {
            require(rsTokenBalance >= assets, "Insufficient balance");
            rasaPool.withdraw(address(assetToken), assets, msg.sender);
            emit AssetsWithdrawn(assets);
        }
    }

    function _supply(uint256 assets) internal {
        console.log("RasaStrategy - balance of assetToken before supply", assetToken.balanceOf(address(this)));
        console.log("RasaStrategy - balance of rsToken before supply", IERC20(rsToken).balanceOf(address(this)));
        rasaPool.supply(address(assetToken), assets, address(this), 0);
        console.log("RasaStrategy - balance of rsToken after supply", IERC20(rsToken).balanceOf(address(this)));
        console.log("RasaStrategy - balance of assetToken after supply", assetToken.balanceOf(address(this)));
        console.log("RasaStrategy - rsToken address", rsToken);
        console.log("RasaStrategy - rasa strategy address", address(this));
        emit AssetsSupplied(assets);
    }

    function asset(address) external view override returns (address) {
        return address(assetToken);
    }

    function totalAssets(address) external view override returns (uint256) {
        return IERC20(rsToken).balanceOf(address(this));
    }

    function maxDeposit(address) external view override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address) external view override returns (uint256) {
        console.log("RasaStrategy - maxWithdraw", IERC20(rsToken).balanceOf(address(this)));
        return IERC20(rsToken).balanceOf(address(this));
    }

    function storageSlot() external pure override returns (bytes32) {
        return keccak256("rasa.strategy.storage");
    }
}
