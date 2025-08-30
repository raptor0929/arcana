// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Arcana} from "../src/Arcana.sol";
import {MorphoStrategy} from "../src/MorphoStrategy.sol";
import {RasaStrategy} from "../src/RasaStrategy.sol";
import {MockToken} from "./mocks/MockToken.sol";
import {MockMorphoVault} from "./mocks/MockMorphoVault.sol";
import {MockRasaPool} from "./mocks/MockRasaPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract ArcanaTest is Test {
    Arcana public arcana;
    MorphoStrategy public morphoStrategy;
    RasaStrategy public rasaStrategy;
    
    // Mock contracts
    MockToken public mockAsset;
    MockMorphoVault public mockMorphoVault;
    MockRasaPool public mockRasaPool;

    address public user = address(1);

    function setUp() public {
        // Deploy mock contracts
        mockAsset = new MockToken("Mock USDC", "USDC");
        mockMorphoVault = new MockMorphoVault(IERC20(mockAsset));
        mockRasaPool = new MockRasaPool(IERC20(mockAsset));

        // Deploy strategies
        morphoStrategy = new MorphoStrategy(IERC20(mockAsset), mockMorphoVault);
        rasaStrategy = new RasaStrategy(IERC20(mockAsset), mockRasaPool);

        // Deploy Arcana vault
        arcana = new Arcana(IERC20(mockAsset), "Arcana Vault", "aARCANA");

        // Give user some tokens
        mockAsset.mint(user, 10000);
    }

    function test_SetupWithBothStrategies() public {
        // Add Morpho strategy
        bytes memory morphoInitData = "";
        arcana.addStrategy(address(morphoStrategy), morphoInitData);

        // Add Rasa strategy
        bytes memory rasaInitData = ""; // Rasa doesn't need init data
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        assertEq(arcana.numStrategies(), 2);
    }

    function test_DepositOnlyToMorpho() public {
        // Setup: Add only Morpho strategy
        bytes memory morphoInitData = "";
        arcana.addStrategy(address(morphoStrategy), morphoInitData);

        // Approve and deposit
        vm.startPrank(user);
        console.log("user balance", mockAsset.balanceOf(user));
        mockAsset.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Verify deposit went to Morpho strategy
        assertEq(arcana.totalSupply(), 1000, "total shares should be 1000");
        assertEq(morphoStrategy.shares(), 1000, "morpho strategy shares should be 1000");
        assertEq(mockMorphoVault.shares(address(morphoStrategy)), 1000);
    }

    function test_WithdrawFromMorpho() public {
        // Setup: Add only Morpho strategy
        bytes memory morphoInitData = abi.encodePacked(address(mockMorphoVault));
        arcana.addStrategy(address(morphoStrategy), morphoInitData);

        // Initial deposit
        vm.startPrank(user);
        mockAsset.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Withdraw 500 tokens
        vm.startPrank(user);
        arcana.withdraw(500, user, user);
        vm.stopPrank();

        // Verify withdrawal
        assertEq(arcana.totalAssets(), 500);
        assertEq(morphoStrategy.shares(), 500); // Strategy tracks shares internally
        assertEq(mockMorphoVault.shares(address(morphoStrategy)), 500); // Morpho vault tracks strategy's shares
        assertEq(mockAsset.balanceOf(user), 9500); // 10000 - 1000 + 500
    }

    function test_DepositToMorphoAndRebalanceHalfToRasa() public {
        // Setup: Add both strategies
        bytes memory morphoInitData = "";
        arcana.addStrategy(address(morphoStrategy), morphoInitData);

        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        // Initial deposit to Morpho
        vm.startPrank(user);
        mockAsset.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Verify initial state
        assertEq(arcana.totalAssets(), 1000);
        assertEq(morphoStrategy.shares(), 1000); // Strategy tracks shares internally
        assertEq(mockMorphoVault.shares(address(morphoStrategy)), 1000); // Morpho vault tracks strategy's shares
        assertEq(mockRasaPool.aTokenBalances(address(arcana)), 0);

        // Rebalance: move 500 from Morpho (index 0) to Rasa (index 1)
        arcana.rebalance(0, 1, 500);

        // Verify rebalance
        assertEq(arcana.totalSupply(), 1000, "total shares should be 1000"); // Total should remain the same
        assertEq(morphoStrategy.shares(), 500, "morpho strategy shares should be 500"); // Half moved out from Morpho strategy
        assertEq(mockMorphoVault.shares(address(morphoStrategy)), 500, "morpho vault shares should be 500"); // Morpho vault tracks strategy's shares
        assertEq(mockRasaPool.aTokenBalances(address(rasaStrategy)), 500, "rasa pool should have 500 tokens remaining"); // Half moved in to Rasa
    }

    function test_DepositOnlyToRasa() public {
        // Setup: Add only Rasa strategy
        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        // Approve and deposit
        vm.startPrank(user);
        mockAsset.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Verify deposit went to Rasa strategy
        assertEq(arcana.totalSupply(), 1000, "total shares should be 1000");
        assertEq(mockRasaPool.aTokenBalances(address(rasaStrategy)), 1000, "rasa pool should have 1000 tokens");
    }

    function test_WithdrawFromRasa() public {
        // Setup: Add only Rasa strategy
        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        // Initial deposit
        vm.startPrank(user);
        mockAsset.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Withdraw 500 tokens
        vm.startPrank(user);
        arcana.withdraw(500, user, user);
        vm.stopPrank();

        // Verify withdrawal
        assertEq(arcana.totalAssets(), 500, "vault should have 500 assets remaining");
        assertEq(mockRasaPool.aTokenBalances(address(rasaStrategy)), 500, "rasa pool should have 500 tokens remaining");
        assertEq(mockAsset.balanceOf(user), 9500, "user should have 9500 tokens"); // 10000 - 1000 + 500
    }

    function test_DepositToRasaAndRebalanceHalfToMorpho() public {
        // Setup: Add both strategies (Rasa first so it gets index 0)
        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        bytes memory morphoInitData = "";
        arcana.addStrategy(address(morphoStrategy), morphoInitData);

        // Initial deposit to Rasa
        vm.startPrank(user);
        mockAsset.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Verify initial state
        assertEq(arcana.totalAssets(), 1000);
        assertEq(mockRasaPool.aTokenBalances(address(rasaStrategy)), 1000); // Rasa strategy holds aTokens
        assertEq(morphoStrategy.shares(), 0); // Morpho strategy has no shares initially
        assertEq(mockMorphoVault.shares(address(morphoStrategy)), 0);

        // Rebalance: move 500 from Rasa (index 0) to Morpho (index 1)
        arcana.rebalance(0, 1, 500);

        // Verify rebalance
        assertEq(arcana.totalSupply(), 1000, "total shares should be 1000"); // Total should remain the same
        assertEq(mockRasaPool.aTokenBalances(address(rasaStrategy)), 500, "rasa pool should have 500 tokens remaining"); // Half moved out from Rasa
        assertEq(morphoStrategy.shares(), 500, "morpho strategy shares should be 500"); // Half moved in to Morpho
        assertEq(mockMorphoVault.shares(address(morphoStrategy)), 500, "morpho vault shares should be 500"); // Morpho vault tracks strategy's shares
    }
}
