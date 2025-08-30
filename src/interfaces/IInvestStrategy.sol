// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IInvestStrategy {
  function connect(bytes memory initData) external;
  function disconnect(bool force) external;
  function deposit(uint256 assets) external;
  function withdraw(uint256 assets) external;
  function asset(address contract_) external view returns (address);
  function totalAssets(address contract_) external view returns (uint256 totalManagedAssets);
  function maxDeposit(address contract_) external view returns (uint256 maxAssets);
  function maxWithdraw(address contract_) external view returns (uint256 maxAssets);
  function storageSlot() external view returns (bytes32);
}