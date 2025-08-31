// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import {Arcana} from "../src/Arcana.sol";
import {MorphoStrategy} from "../src/MorphoStrategy.sol";
import {RasaStrategy} from "../src/RasaStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaMorpho} from "../src/interfaces/IMetaMorpho.sol";
import {IRasaPool} from "../src/interfaces/IRasaPool.sol";
import {console} from "forge-std/console.sol";

/**
 * @title DeployScript
 * @dev Deployment script for the Arcana vault system including strategies.
 *      Deploys the main vault, Morpho strategy, and Rasa strategy with
 *      proper initialization and configuration.
 */
contract DeployScript is Script {
    /// @dev The main Arcana vault contract
    Arcana public arcana;
    
    /// @dev The Morpho investment strategy
    MorphoStrategy public morphoStrategy;
    
    /// @dev The Rasa investment strategy
    RasaStrategy public rasaStrategy;
    
    // Contract addresses from ArcanaIntegration test
    /// @dev The underlying asset token (e.g., USDC, DAI)
    IERC20 public assetToken;
    
    /// @dev The Morpho MetaMorpho vault address
    IMetaMorpho public morphoVault;
    
    /// @dev The Rasa lending pool address
    IRasaPool public rasaPool;
    
    /// @dev The Rasa RS token address
    address public rsToken;

    /**
     * @dev Main deployment function that sets up the entire Arcana system
     */
    function run() public {
        vm.startBroadcast();

        // Use the same addresses as ArcanaIntegration test
        assetToken = IERC20(0xac485391EB2d7D88253a7F1eF18C37f4242D1A24);
        morphoVault = IMetaMorpho(0x8258F0c79465c95AFAc325D6aB18797C9DDAcf55);
        rasaPool = IRasaPool(0x617a09f69493560f23B8Da05ADf98CE3B52d7A99);

        // Get RS token address from Rasa pool
        (,,,,,,,, rsToken,,,,,,) = rasaPool.getReserveData(address(assetToken));
        console.log("Asset Token:", address(assetToken));
        console.log("Morpho Vault:", address(morphoVault));
        console.log("Rasa Pool:", address(rasaPool));
        console.log("RS Token:", rsToken);

        // Deploy strategies
        morphoStrategy = new MorphoStrategy(assetToken, morphoVault);
        rasaStrategy = new RasaStrategy(assetToken, rasaPool);
        console.log("Morpho Strategy deployed at:", address(morphoStrategy));
        console.log("Rasa Strategy deployed at:", address(rasaStrategy));

        // Deploy Arcana vault
        arcana = new Arcana(assetToken, "Arcana Vault", "aARCANA");
        console.log("Arcana Vault deployed at:", address(arcana));

        // Add both strategies to the vault
        bytes memory morphoInitData = "";
        arcana.addStrategy(address(morphoStrategy), morphoInitData);
        console.log("Morpho Strategy added to vault");

        bytes memory rasaInitData = "";
        arcana.addStrategy(address(rasaStrategy), rasaInitData);
        console.log("Rasa Strategy added to vault");

        // Verify setup
        console.log("Number of strategies in vault:", arcana.numStrategies());
        console.log("Arcana total assets:", arcana.totalAssets());

        vm.stopBroadcast();
    }
}
