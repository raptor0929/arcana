// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRasaPool} from "../../src/interfaces/IRasaPool.sol";
import {MockToken} from "./MockToken.sol";

/**
 * @title MockRasaPool
 * @dev Mock Rasa pool for testing
 */
contract MockRasaPool is IRasaPool {
    IERC20 public immutable asset;
    mapping(address => uint256) public aTokenBalances;
    uint256 public totalATokens;
    MockToken public immutable aToken;

    constructor(IERC20 _asset) {
        asset = _asset;
        aToken = new MockToken("Rasa AToken", "RASA");
        aToken.mint(address(this), 1000000e6);
    }

    function supply(address _asset, uint256 amount, address onBehalfOf, uint16) external {
        require(_asset == address(asset), "Wrong asset");
        require(amount > 0, "Zero amount");
        
        // Simple 1:1 ratio for testing
        aTokenBalances[onBehalfOf] += amount;
        totalATokens += amount;
        
        // Transfer assets from caller
        IERC20(asset).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address _asset, uint256 amount, address to) external returns (uint256) {
        require(_asset == address(asset), "Wrong asset");
        require(amount > 0, "Zero amount");
        require(aTokenBalances[msg.sender] >= amount, "Insufficient balance");
        
        aTokenBalances[msg.sender] -= amount;
        totalATokens -= amount;
        
        // Transfer assets to recipient
        IERC20(asset).transfer(to, amount);
        return amount;
    }

    function balanceOf(address owner) external view returns (uint256) {
        return aTokenBalances[owner];
    }

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
        
        // Return mock data - aTokenAddress is this contract
        return (
            1, // configuration (active)
            1e27, // liquidityIndex
            1e27, // variableBorrowIndex
            0, // currentLiquidityRate
            0, // currentVariableBorrowRate
            0, // currentStableBorrowRate
            uint40(block.timestamp), // lastUpdateTimestamp
            0, // id
            address(aToken), // aTokenAddress (this contract)
            address(0), // stableDebtTokenAddress
            address(0), // variableDebtTokenAddress
            address(0), // interestRateStrategyAddress
            0, // accruedToTreasury
            0, // unbacked
            0 // isolationModeTotalDebt
        );
    }
}
