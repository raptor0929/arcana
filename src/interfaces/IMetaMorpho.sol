// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IMetaMorpho {
    // Deposit assets and mint shares to receiver
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    // Redeem shares for assets and transfer to receiver
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    // Preview how many assets would be received for redeeming shares
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    // Withdraw assets and burn shares from owner
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    // Preview how many shares would be burned for withdrawing assets
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    // Get the underlying asset address
    function asset() external view returns (address);
    // Get the share balance of an owner
    function balanceOf(address owner) external view returns (uint256);
}