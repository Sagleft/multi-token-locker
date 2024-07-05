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

    constructor() Ownable(msg.sender) {}

    function lockTokens(address _recipient, uint256 _unlockTimestamp, uint256 _amount, address _token) external payable onlyOwner {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");

        // Ensure the contract has enough tokens
        IERC20 tokenContract = IERC20(_token);
        require(tokenContract.balanceOf(address(this)) >= _amount, "Insufficient balance");

        // Lock the tokens
        locks[_recipient].push(Lock(_recipient, _unlockTimestamp, _amount, _token));
    }

    function unlockTokens(address _recipient, address _token) external payable {
        Lock[] storage userLocks = locks[_recipient];
        uint256 totalUnlockedAmount;
        uint256 length = userLocks.length;
        uint256[] memory indicesToRemove = new uint256[](length);
        uint256 removeCount = 0;

        // get total amount
        for (uint256 i = 0; i < length; i++) {
            if (userLocks[i].unlockTimestamp <= block.timestamp) {
                totalUnlockedAmount += userLocks[i].amount;
                indicesToRemove[removeCount] = i;
                removeCount++;
            }
        }

        require(totalUnlockedAmount > 0, "No tokens to unlock");

        // try transfer
        IERC20(_token).safeTransfer(_recipient, totalUnlockedAmount);

        for (uint256 i = 0; i < removeCount; i++) {
            uint256 indexToRemove = indicesToRemove[i];
            if (indexToRemove != userLocks.length - 1) {
                userLocks[indexToRemove] = userLocks[userLocks.length - 1];
            }
            userLocks.pop();
        }
    }
}
