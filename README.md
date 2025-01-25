# multi-token-locker
Tokens Locker

# Deploy the Contract:

in testnet:

```
truffle migrate --network testnet
```

# Interact with the Contract:
Once deployed, you can setup the contract using the following functions:

***Lock Tokens:***
Call the lockTokens function, specifying the token address, the amount to lock, and the lock duration (in seconds).

***Unlock Tokens:***
After the lock duration has elapsed, call the unlockTokens function to retrieve the locked tokens.
