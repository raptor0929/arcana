// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IMetaMorpho
 * @dev Interface for Morpho MetaMorpho vaults, which are ERC4626-compatible
 *      yield-generating vaults that aggregate lending positions across multiple
 *      protocols for optimal capital efficiency.
 */
interface IMetaMorpho {
    /**
     * @dev Deposits assets and mints shares to the receiver
     * @param assets Amount of assets to deposit
     * @param receiver Address to receive the minted shares
     * @return shares Amount of shares minted to the receiver
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    
    /**
     * @dev Redeems shares for assets and transfers to receiver
     * @param shares Amount of shares to redeem
     * @param receiver Address to receive the redeemed assets
     * @param owner Address whose shares will be burned
     * @return assets Amount of assets redeemed
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    
    /**
     * @dev Preview how many assets would be received for redeeming shares
     * @param shares Amount of shares to preview redemption for
     * @return assets Amount of assets that would be received
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    
    /**
     * @dev Withdraws assets and burns shares from owner
     * @param assets Amount of assets to withdraw
     * @param receiver Address to receive the withdrawn assets
     * @param owner Address whose shares will be burned
     * @return shares Amount of shares burned
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    
    /**
     * @dev Preview how many shares would be burned for withdrawing assets
     * @param assets Amount of assets to preview withdrawal for
     * @return shares Amount of shares that would be burned
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    
    /**
     * @dev Returns the address of the underlying asset token
     * @return Address of the underlying asset token
     */
    function asset() external view returns (address);
    
    /**
     * @dev Returns the share balance of an owner
     * @param owner Address to check balance for
     * @return Amount of shares owned by the address
     */
    function balanceOf(address owner) external view returns (uint256);
}