// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./SafeERC20.sol";

contract MultiLocker {
    using SafeERC20 for IERC20;

    address public owner;
    mapping(address => uint256) public lockedBalances;   // token address -> amount
    mapping(address => uint256) public lockedTimestamps; // token address -> unlockTimestamp

    event TokensLocked(address indexed user, address indexed token, uint256 amount, uint256 lockDuration);
    event TokensUnlocked(address indexed user, address indexed token, uint256 amount);
    event DestinationChanged(address indexed oldDestination, address indexed newDestination);
    event DurationExtended(address indexed user, address indexed token, uint256 lockDuration);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor() {
        owner = msg.sender; 
    }

    function toSmallestUnit(address _token, uint256 _amount) internal view returns (uint256) {
        IERC20 token = IERC20(_token);
        uint8 decimals = token.decimals();
        return _amount * (10 ** uint256(decimals));
    }

		// Lock Tokens for the specified duration
    function lockTokens(address _token, uint256 _amount, uint256 _unlockTimestamp) external onlyOwner {
        require(_amount > 0, "Amount is zero");
        require(_unlockTimestamp > block.timestamp, "Invalid lock duration");

        uint8 decimals = token.decimals();
        uint256 amountInSmallestUnit = _amount * (10 ** uint256(decimals));

        // transfer tokens to contract
        IERC20(_token).safeTransferFrom(msg.sender, address(this), amountInSmallestUnit);

        // increment locked amount
        lockedBalances[_token] = lockedBalances[_token] + amountInSmallestUnit;
        if (_unlockTimestamp > lockedTimestamps[_token]) {
          lockedTimestamps[_token] = _unlockTimestamp;
        }

        emit TokensLocked(msg.sender, _token, amountInSmallestUnit, _unlockTimestamp);
    }

		// Unlock Tokens after the specified duration
    function unlockTokens(address _token) external onlyOwner {
        require(lockedBalances[_token] > 0, "No tokens are locked for this token");
        require(block.timestamp >= lockedTimestamps[_token], "Tokens cannot be unlocked yet");

        // transfer tokens
        uint8 decimals = token.decimals();
        uint256 amountInSmallestUnit = lockedBalances[_token] * (10 ** uint256(decimals));
        IERC20(_token).safeTransfer(owner, amountInSmallestUnit);

        // reset lock
        lockedTimestamps[_token] = 0;
        lockedBalances[_token] = 0;

        emit TokensUnlocked(msg.sender, _token, amountInSmallestUnit);
    }

		// Change owner of contract & receiver of token(s)
    function changeDestination(address _newDestination) external onlyOwner {
        require(_newDestination != address(0), "Invalid destination address");
        require(_newDestination != owner, "New destination must be different from current owner");

        // change contract owner
        owner = _newDestination;

        emit DestinationChanged(owner, _newDestination);
    }

		// Extend the lock duration (unix timestamp)
    function extendDuration(address _token, uint256 _newTimestamp) external onlyOwner {
        require(_newTimestamp > block.timestamp, "New lock duration must be greater than previous duration");
        require(_newTimestamp > lockedTimestamps[_token], "New timestamp shold be greater than old timestamp");

        // change locker duration
        lockedTimestamps[_token] = _newTimestamp;

        emit DurationExtended(msg.sender, _token, _newTimestamp);
    }
}
