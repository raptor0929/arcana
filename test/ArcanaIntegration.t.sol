// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Arcana} from "../src/Arcana.sol";
import {MorphoStrategy} from "../src/MorphoStrategy.sol";
import {RasaStrategy} from "../src/RasaStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";
import {IMetaMorpho} from "../src/interfaces/IMetaMorpho.sol";
import {IRasaPool} from "../src/interfaces/IRasaPool.sol";

contract ArcanaIntegrationTest is Test {
    Arcana public arcana;
    MorphoStrategy public morphoStrategy;
    RasaStrategy public rasaStrategy;
    
    // Mock contracts
    IERC20 public assetToken;
    IMetaMorpho public morphoVault;
    IRasaPool public rasaPool;
    address public rsToken;

    address public user = address(1);
    address public whale;

    function setUp() public {
        // Fork mainnet
        uint256 liskForkBlock = 20_911_637;
        vm.createSelectFork(vm.rpcUrl("lisk"), liskForkBlock);

        // Deploy mock contracts
        assetToken = IERC20(0xac485391EB2d7D88253a7F1eF18C37f4242D1A24);
        morphoVault = IMetaMorpho(0x8258F0c79465c95AFAc325D6aB18797C9DDAcf55);
        rasaPool = IRasaPool(0x617a09f69493560f23B8Da05ADf98CE3B52d7A99);
        whale = address(0xdEA264322978933724d2147C45ddd186E7994A8c);

        (,,,,,,,, rsToken,,,,,,) = rasaPool.getReserveData(address(assetToken));

        // Deploy strategies
        morphoStrategy = new MorphoStrategy(IERC20(assetToken), morphoVault);
        rasaStrategy = new RasaStrategy(IERC20(assetToken), rasaPool);

        // Deploy Arcana vault
        arcana = new Arcana(IERC20(assetToken), "Arcana Vault", "aARCANA");

        // Give user some tokens
        vm.startPrank(whale);
        assetToken.transfer(user, 10000);
        vm.stopPrank();
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
        console.log("user balance", assetToken.balanceOf(user));
        assetToken.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Verify deposit went to Morpho strategy
        assertEq(arcana.totalSupply(), 1000, "total shares should be 1000");
        assertEq(morphoStrategy.shares(), 999, "morpho strategy shares should be 1000");
        assertEq(morphoVault.balanceOf(address(morphoStrategy)), 999, "morpho vault should have 999 shares");
    }

    function test_WithdrawFromMorpho() public {
        // Setup: Add only Morpho strategy
        bytes memory morphoInitData = abi.encodePacked(address(morphoVault));
        arcana.addStrategy(address(morphoStrategy), morphoInitData);

        // Initial deposit
        vm.startPrank(user);
        assetToken.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Withdraw 500 tokens
        vm.startPrank(user);
        arcana.withdraw(500, user, user);
        vm.stopPrank();

        // Verify withdrawal
        assertEq(arcana.totalAssets(), 499, "total assets should be 499");
        assertEq(morphoStrategy.shares(), 499, "morpho strategy shares should be 500"); // Strategy tracks shares internally
        assertEq(morphoVault.balanceOf(address(morphoStrategy)), 499, "morpho vault should have 499 shares"); // Morpho vault tracks strategy's shares
        assertEq(assetToken.balanceOf(user), 9500); // 10000 - 1000 + 500
    }

    function test_DepositToMorphoAndRebalanceHalfToRasa() public {
        // Setup: Add both strategies
        bytes memory morphoInitData = "";
        arcana.addStrategy(address(morphoStrategy), morphoInitData);

        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        // Initial deposit to Morpho
        vm.startPrank(user);
        assetToken.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Verify initial state
        assertEq(arcana.totalAssets(), 999, "total assets should be 999");
        assertEq(morphoStrategy.shares(), 999, "morpho strategy shares should be 999"); // Strategy tracks shares internally
        assertEq(morphoVault.balanceOf(address(morphoStrategy)), 999, "morpho vault should have 999 shares"); // Morpho vault tracks strategy's shares
        assertEq(IERC20(rsToken).balanceOf(address(rasaStrategy)), 0, "rasa strategy should have 0 tokens");

        // Rebalance: move 500 from Morpho (index 0) to Rasa (index 1)
        arcana.rebalance(0, 1, 500);

        // Verify rebalance
        assertEq(arcana.totalSupply(), 1000, "total shares should be 1000"); // Total should remain the same
        assertEq(morphoStrategy.shares(), 499, "morpho strategy shares should be 499"); // Half moved out from Morpho strategy
        assertEq(morphoVault.balanceOf(address(morphoStrategy)), 499, "morpho vault shares should be 499"); // Morpho vault tracks strategy's shares
        assertEq(IERC20(rsToken).balanceOf(address(rasaStrategy)), 500, "rasa pool should have 500 tokens remaining"); // Half moved in to Rasa
    }

    function test_DepositOnlyToRasa() public {
        // Setup: Add only Rasa strategy
        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        // Approve and deposit
        vm.startPrank(user);
        assetToken.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Verify deposit went to Rasa strategy
        assertEq(arcana.totalSupply(), 1000, "total shares should be 1000");
        console.log("rsToken address", rsToken);
        console.log("rsToken address from strategy", rasaStrategy.rsToken());
        console.log("rToken balance rasa strategy", IERC20(rsToken).balanceOf(address(rasaStrategy)));
        console.log("rToken balance rasa pool", IERC20(rsToken).balanceOf(address(rasaPool)));
        console.log("rToken balance arcana", IERC20(rsToken).balanceOf(address(arcana)));
        console.log("rToken balance user", IERC20(rsToken).balanceOf(user));
        console.log("rToken balance this", IERC20(rsToken).balanceOf(address(this)));
        console.log("rasa strategy address", address(rasaStrategy));
        assertEq(IERC20(rsToken).balanceOf(address(rasaStrategy)), 1000, "rasa pool should have 1000 tokens");
    }

    function test_WithdrawFromRasa() public {
        // Setup: Add only Rasa strategy
        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        // Initial deposit
        vm.startPrank(user);
        assetToken.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Withdraw 500 tokens
        vm.startPrank(user);
        arcana.withdraw(500, user, user);
        vm.stopPrank();

        // Verify withdrawal
        assertEq(arcana.totalAssets(), 500, "vault should have 500 assets remaining");
        assertEq(IERC20(rsToken).balanceOf(address(rasaStrategy)), 500, "rasa pool should have 500 tokens remaining");
        assertEq(assetToken.balanceOf(user), 9500, "user should have 9500 tokens"); // 10000 - 1000 + 500
    }

    function test_DepositToRasaAndRebalanceHalfToMorpho() public {
        // Setup: Add both strategies (Rasa first so it gets index 0)
        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);

        bytes memory morphoInitData = "";
        arcana.addStrategy(address(morphoStrategy), morphoInitData);

        // Initial deposit to Rasa
        vm.startPrank(user);
        assetToken.approve(address(arcana), 1000);
        arcana.deposit(1000, user);
        vm.stopPrank();

        // Verify initial state
        assertEq(arcana.totalAssets(), 1000, "total assets should be 1000");
        assertEq(IERC20(rsToken).balanceOf(address(rasaStrategy)), 1000, "rasa strategy should have 1000 tokens"); // Rasa strategy holds rsTokens
        assertEq(morphoStrategy.shares(), 0, "morpho strategy should have 0 shares"); // Morpho strategy has no shares initially
        assertEq(morphoVault.balanceOf(address(morphoStrategy)), 0, "morpho vault should have 0 shares");

        // Rebalance: move 500 from Rasa (index 0) to Morpho (index 1)
        arcana.rebalance(0, 1, 500);

        // Verify rebalance
        assertEq(arcana.totalSupply(), 1000, "total shares should be 1000"); // Total should remain the same
        assertEq(IERC20(rsToken).balanceOf(address(rasaStrategy)), 500, "rasa pool should have 500 tokens remaining"); // Half moved out from Rasa
        assertEq(morphoStrategy.shares(), 499, "morpho strategy shares should be 499"); // Half moved in to Morpho
        assertEq(morphoVault.balanceOf(address(morphoStrategy)), 499, "morpho vault shares should be 499"); // Morpho vault tracks strategy's shares
    }
}
