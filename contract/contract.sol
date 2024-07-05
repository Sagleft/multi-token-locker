// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TokenLocker {
    address public owner;
    
    struct Lock {
        uint256 unlockTimestamp; // seconds
        uint256 amount;
    }

    mapping(address => Lock[]) public locks;

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

    function lockTokens(address _recipient, uint256 _unlockTimestamp) external payable onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(msg.value > 0, "Amount must be greater than zero");

        // Lock the tokens
        locks[_recipient].push(Lock(_unlockTimestamp, msg.value));
    }

    function unlockTokens(address _recipient) external {
        Lock[] storage userLocks = locks[_recipient];
        uint256 totalUnlockedAmount = 0;
        uint256 i = 0;

        while (i < userLocks.length) {
            if (userLocks[i].unlockTimestamp <= block.timestamp) {
                totalUnlockedAmount += userLocks[i].amount;
                // Перемещаем последний элемент на место текущего
                userLocks[i] = userLocks[userLocks.length - 1];
                userLocks.pop();
            } else {
                i++;
            }
        }

        require(totalUnlockedAmount > 0, "No tokens to unlock");

        // Transfer unlocked tokens to the recipient
        payable(_recipient).transfer(totalUnlockedAmount);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
