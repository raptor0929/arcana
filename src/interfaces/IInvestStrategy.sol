// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IInvestStrategy {
  // Initialize strategy with configuration data
  function connect(bytes memory initData) external;
  // Disconnect strategy, optionally forcing withdrawal of all assets
  function disconnect(bool force) external;
  // Deposit assets into the underlying protocol
  function deposit(uint256 assets) external;
  // Withdraw assets from the underlying protocol
  function withdraw(uint256 assets) external;
  // Get the underlying asset address
  function asset(address contract_) external view returns (address);
  // Get total assets managed by this strategy
  function totalAssets(address contract_) external view returns (uint256 totalManagedAssets);
  // Get maximum amount that can be deposited
  function maxDeposit(address contract_) external view returns (uint256 maxAssets);
  // Get maximum amount that can be withdrawn
  function maxWithdraw(address contract_) external view returns (uint256 maxAssets);
  // Get unique storage slot for this strategy
  function storageSlot() external view returns (bytes32);
}