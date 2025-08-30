// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IMetaMorpho {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function asset() external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
}