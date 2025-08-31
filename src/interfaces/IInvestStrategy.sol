// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IInvestStrategy
 * @dev Interface for investment strategies that can be integrated with the Arcana vault.
 *      Defines the standard interface that all strategies must implement to enable
 *      dynamic asset allocation and yield generation across multiple protocols.
 */
interface IInvestStrategy {
  /**
   * @dev Initializes the strategy with configuration data
   * @param initData Initialization data specific to the strategy implementation
   */
  function connect(bytes memory initData) external;
  
  /**
   * @dev Disconnects the strategy, optionally forcing withdrawal of all assets
   * @param force If true, forces disconnection even if strategy has assets
   */
  function disconnect(bool force) external;
  
  /**
   * @dev Deposits assets into the underlying protocol
   * @param assets Amount of assets to deposit
   */
  function deposit(uint256 assets) external;
  
  /**
   * @dev Withdraws assets from the underlying protocol
   * @param assets Amount of assets to withdraw
   */
  function withdraw(uint256 assets) external;
  
  /**
   * @dev Returns the address of the underlying asset token
   * @param contract_ Address of the contract requesting the asset info
   * @return Address of the underlying asset token
   */
  function asset(address contract_) external view returns (address);
  
  /**
   * @dev Returns the total assets managed by this strategy
   * @param contract_ Address of the contract requesting the total assets
   * @return totalManagedAssets Total assets value in the underlying asset token
   */
  function totalAssets(address contract_) external view returns (uint256 totalManagedAssets);
  
  /**
   * @dev Returns the maximum amount that can be deposited
   * @param contract_ Address of the contract requesting the deposit limit
   * @return maxAssets Maximum amount that can be deposited
   */
  function maxDeposit(address contract_) external view returns (uint256 maxAssets);
  
  /**
   * @dev Returns the maximum amount that can be withdrawn
   * @param contract_ Address of the contract requesting the withdrawal limit
   * @return maxAssets Maximum amount that can be withdrawn
   */
  function maxWithdraw(address contract_) external view returns (uint256 maxAssets);
  
  /**
   * @dev Returns a unique storage slot identifier for this strategy
   * @return Unique bytes32 identifier for the strategy
   */
  function storageSlot() external view returns (bytes32);
}