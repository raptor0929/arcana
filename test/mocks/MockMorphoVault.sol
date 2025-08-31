// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaMorpho} from "../../src/interfaces/IMetaMorpho.sol";

/**
 * @title MockMorphoVault
 * @dev Mock implementation of Morpho MetaMorpho vault for testing purposes.
 *      Provides a simplified 1:1 asset-to-share ratio for easy testing.
 */
contract MockMorphoVault is IMetaMorpho {
    /// @dev The underlying asset token (e.g., USDC, DAI)
    IERC20 public immutable assetToken;
    
    /// @dev Mapping of user addresses to their share balances
    mapping(address => uint256) public shares;

    /**
     * @dev Constructor to initialize the mock vault with an asset token
     * @param _asset The ERC20 token to be used as the underlying asset
     */
    constructor(IERC20 _asset) {
        assetToken = _asset;
    }

    /**
     * @dev Deposits assets and mints shares to the receiver
     * @param assets Amount of assets to deposit
     * @param receiver Address to receive the minted shares
     * @return Amount of shares minted (1:1 ratio for simplicity)
     */
    function deposit(uint256 assets, address receiver) override external returns (uint256) {
        require(assets > 0, "Zero assets");
        
        shares[receiver] += assets;
        assetToken.transferFrom(msg.sender, address(this), assets);
        
        return assets; // 1:1 ratio for simplicity
    }

    /**
     * @dev Withdraws assets by burning shares from the owner
     * @param assets Amount of assets to withdraw
     * @param receiver Address to receive the withdrawn assets
     * @param owner Address whose shares will be burned
     * @return Amount of shares burned (1:1 ratio for simplicity)
     */
    function withdraw(uint256 assets, address receiver, address owner) override external returns (uint256) {
        require(assets > 0, "Zero assets");
        require(shares[owner] >= assets, "Insufficient balance");
        
        shares[owner] -= assets;
        assetToken.transfer(receiver, assets);
        
        return assets; // 1:1 ratio for simplicity
    }

    /**
     * @dev Redeems shares for assets and transfers to receiver
     * @param sharesAmount Amount of shares to redeem
     * @param receiver Address to receive the redeemed assets
     * @param owner Address whose shares will be burned
     * @return Amount of assets redeemed (1:1 ratio for simplicity)
     */
    function redeem(uint256 sharesAmount, address receiver, address owner) override external returns (uint256) {
        require(sharesAmount > 0, "Zero shares");
        require(shares[owner] >= sharesAmount, "Insufficient balance");
        
        shares[owner] -= sharesAmount;
        assetToken.transfer(receiver, sharesAmount);
        
        return sharesAmount; // 1:1 ratio for simplicity
    }

    /**
     * @dev Preview how many assets would be received for redeeming shares
     * @param sharesAmount Amount of shares to preview redemption for
     * @return Amount of assets that would be received
     */
    function previewRedeem(uint256 sharesAmount) override external pure returns (uint256) {
        return sharesAmount; // 1:1 ratio for simplicity
    }

    /**
     * @dev Preview how many shares would be burned for withdrawing assets
     * @param assets Amount of assets to preview withdrawal for
     * @return Amount of shares that would be burned
     */
    function previewWithdraw(uint256 assets) override external pure returns (uint256) {
        return assets; // 1:1 ratio for simplicity
    }

    /**
     * @dev Returns the address of the underlying asset token
     * @return Address of the asset token
     */
    function asset() override external view returns (address) {
        return address(assetToken);
    }

    /**
     * @dev Returns the share balance of an owner
     * @param owner Address to check balance for
     * @return Amount of shares owned by the address
     */
    function balanceOf(address owner) override external view returns (uint256) {
        return shares[owner];
    }
}
