// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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

    // Lock Tokens for the specified duration
    function lockTokens(address _token, uint256 _amount, uint256 _unlockTimestamp) external payable onlyOwner {
        require(_amount > 0, "Amount is zero");
        require(_unlockTimestamp > block.timestamp, "Invalid lock duration");

        // transfer tokens to contract
        bool success = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        // increment locked amount
        lockedBalances[_token] += _amount;
        if (_unlockTimestamp > lockedTimestamps[_token]) {
            lockedTimestamps[_token] = _unlockTimestamp;
        }

        emit TokensLocked(msg.sender, _token, _amount, _unlockTimestamp);
    }

    // Unlock Tokens after the specified duration
    function unlockTokens(address _token) external payable onlyOwner {
        require(lockedBalances[_token] > 0, "No tokens are locked for this token");
        require(block.timestamp >= lockedTimestamps[_token], "Tokens cannot be unlocked yet");

        // transfer tokens
        uint256 amount = lockedBalances[_token];
        bool success = IERC20(_token).transfer(owner, amount);
        require(success, "Token transfer failed");

        // reset lock
        lockedTimestamps[_token] = 0;
        lockedBalances[_token] = 0;

        emit TokensUnlocked(msg.sender, _token, amount);
    }

    // Change owner of contract & receiver of token(s)
    function changeDestination(address _newDestination) external payable onlyOwner {
        require(_newDestination != address(0), "Invalid destination address");
        require(_newDestination != owner, "New destination must be different from current owner");

        // change contract owner
        emit DestinationChanged(owner, _newDestination);
        owner = _newDestination;
    }

    // Extend the lock duration (unix timestamp)
    function extendDuration(address _token, uint256 _newTimestamp) external payable onlyOwner {
        require(_newTimestamp > block.timestamp, "New lock duration must be greater than previous duration");
        require(_newTimestamp > lockedTimestamps[_token], "New timestamp should be greater than old timestamp");

        // change locker duration
        lockedTimestamps[_token] = _newTimestamp;

        emit DurationExtended(msg.sender, _token, _newTimestamp);
    }
}
