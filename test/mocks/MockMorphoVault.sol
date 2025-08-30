// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMetaMorpho} from "../../src/interfaces/IMetaMorpho.sol";

/**
 * @title MockMorphoVault
 * @dev Simple mock Morpho vault for testing
 */
contract MockMorphoVault is IMetaMorpho {
    IERC20 public immutable assetToken;
    mapping(address => uint256) public shares;

    constructor(IERC20 _asset) {
        assetToken = _asset;
    }

    function deposit(uint256 assets, address receiver) override external returns (uint256) {
        require(assets > 0, "Zero assets");
        
        shares[receiver] += assets;
        assetToken.transferFrom(msg.sender, address(this), assets);
        
        return assets; // 1:1 ratio for simplicity
    }

    function withdraw(uint256 assets, address receiver, address owner) override external returns (uint256) {
        require(assets > 0, "Zero assets");
        require(shares[owner] >= assets, "Insufficient balance");
        
        shares[owner] -= assets;
        assetToken.transfer(receiver, assets);
        
        return assets; // 1:1 ratio for simplicity
    }

    function redeem(uint256 sharesAmount, address receiver, address owner) override external returns (uint256) {
        require(sharesAmount > 0, "Zero shares");
        require(shares[owner] >= sharesAmount, "Insufficient balance");
        
        shares[owner] -= sharesAmount;
        assetToken.transfer(receiver, sharesAmount);
        
        return sharesAmount; // 1:1 ratio for simplicity
    }

    function previewRedeem(uint256 sharesAmount) override external view returns (uint256) {
        return sharesAmount; // 1:1 ratio for simplicity
    }

    function previewWithdraw(uint256 assets) override external view returns (uint256) {
        return assets; // 1:1 ratio for simplicity
    }

    function asset() override external view returns (address) {
        return address(assetToken);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return shares[owner];
    }
}
