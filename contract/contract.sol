// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./CustomOwnable.sol";

contract TokenLocker is CustomOwnable {
    using SafeERC20 for IERC20;

    struct Lock {
        address recipient;
        uint256 unlockTimestamp; // seconds
        uint256 amount;
        address token;
    }

    mapping(address => Lock[]) public locks;

    event TokensLocked(address indexed recipient, uint256 unlockTimestamp, uint256 amount, address indexed token);
    event TokensUnlocked(address indexed recipient, uint256 amount, address indexed token);

    constructor() Ownable(msg.sender) {}

    function lockTokens(address _recipient, uint256 _unlockTimestamp, uint256 _amount, address _token) external onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");

        // Ensure the contract has enough tokens
        IERC20 tokenContract = IERC20(_token);
        require(tokenContract.balanceOf(address(this)) >= _amount, "Insufficient balance");

        // Lock the tokens
        locks[_recipient].push(Lock(_recipient, _unlockTimestamp, _amount, _token));
        emit TokensLocked(_recipient, _unlockTimestamp, _amount, _token);
    }

    function unlockTokens(address _recipient, address _token) external {
        Lock[] storage userLocks = locks[_recipient];
        uint256 totalUnlockedAmount;

        for (uint256 i = 0; i < userLocks.length; i++) {
            if (userLocks[i].unlockTimestamp <= block.timestamp && userLocks[i].token == _token) {
                totalUnlockedAmount += userLocks[i].amount;
                delete userLocks[i];
            }
        }

        require(totalUnlockedAmount > 0, "No tokens to unlock");

        // Transfer unlocked tokens to the recipient
        IERC20(_token).transfer(_recipient, totalUnlockedAmount);

        for (uint256 i = 0; i < userLocks.length; i++) {
            if (userLocks[i].unlockTimestamp <= block.timestamp && userLocks[i].token == _token) {
                delete userLocks[i];
            }
        }

        emit TokensUnlocked(_recipient, totalUnlockedAmount, _token);
    }
}
