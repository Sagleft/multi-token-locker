// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenLocker {
    address public owner;

    struct Lock {
        address tokenAddress;
        uint256 unlockTimestamp; // seconds
        uint256 amount;
    }

    mapping(address => Lock) public locks;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function lockTokens(address _recipient, address _tokenAddress, uint256 _unlockTimestamp) external payable onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_tokenAddress != address(0), "Invalid token address");
        require(msg.value > 0, "Amount must be greater than zero");

        // Check if a lock already exists for this recipient and token
        require(locks[_recipient].unlockTimestamp == 0, "Lock already exists for this recipient");

        // Lock the tokens
        locks[_recipient] = Lock(_tokenAddress, _unlockTimestamp, msg.value);
    }

    function unlockTokens(address _recipient, address _tokenAddress) external {
        Lock storage userLock = locks[_recipient];
        require(userLock.unlockTimestamp != 0, "No lock found for this recipient");
        require(userLock.tokenAddress == _tokenAddress, "Token address mismatch");
        require(userLock.unlockTimestamp <= block.timestamp, "Lock not yet expired");

        uint256 amountToTransfer = userLock.amount;
        
        // Clear the lock
        delete locks[_recipient];

        // Transfer unlocked tokens to the recipient
        payable(_recipient).transfer(amountToTransfer);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
