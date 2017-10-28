# BokkyPooBah's Token Teleportation Service Smart Contract

Status: Work in progress

## Summary

ERC20 token smart contract that implement the BokkyPooBah's Token Teleportation Service (BTTS)
interface provides Ethereum accounts with the ability to transfer the ERC20 tokens without 
having to pay for the Ethereum network transaction fees in ethers (ETH). Instead, the account
pays for the token transfer fees in the token being transferred.

<br />

### Account Creates Signed Message

Any ERC20 token contracts that implement the *BTTS Interface* with their own *BTTS Implementation*
will be transferable using this *BTTS Service*. An account holding BTTS enabled functions use
the implemented functionality to create a message signed with the account's private key with the
token transfer instructions, including the fees specified in the token being transferred.

<br />

### BTTS Service Provider Executes Token Transfer

The account provides the transfer details and the signed message to the *BTTS Service Provider*.
The *BTTS Service Provider* then executes the appropriate function to execute the token transfer,
paying the transaction fees in ETH. On successful execution of the transfer, the fee in tokens will
be transferred to the *BTTS Service Provider*'s account.

<br />

### Use Cases

Application wallets that implement the message signing technology will be able to cryptographically
sign the token transfer messages, and send the signed messages to the *BTTS Service Providers*.

Users of the application will not even need to know about the cryptographic methods that secure
their tokens.

The application will have to include cryptographic libraries that support the message signing
functionality. The user will install the application and create an account. The account will be
secured by a 12 or 24 word mnemonic phrase. This mnemonic phrase can be used in MyEtherWallet
or the Ledger Nano S hardware wallet to unlock the same set of accounts.


<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [How It Works](#how-it-works)
* [BTTS Interface](#btts-interface)
* [Sample BTTS Implementation](#sample-btts-implementation)
* [Demo On Ropsten Testnet](#demo-on-ropsten-testnet)

<br />

<hr />

## How It Works

This example will explain the results from the testing script and testing results. Note that the computed
hashes will differ in the testing results because new token contract addresses are created in each testing
session.

In the testing:

* The service provider `0xa11a` executes the `signedTransfer(...)` function on behalf of the token owner `0xa33a`
* `from` = `0xa33a`
* `to` = `0xa55a`
* `tokens` = `1`
* `fee` = `0.01`
* The token owner `0xa33a` calculates a hash using the function `var signedTransferHash = token.signedTransferHash(from, to, tokens, fee);`
  This is a hash of the `from`, `to`, `tokens`, `fee` plus some data representing the function name `signedTransfer` and the token contract
  address. Any small difference in this data will result in a different resulting hash.

  The resulting hash is `0xc7e05a63c8b39acaae9a4c0e438f00e30eb69e91d2a960f9dedaea03f662177f`
* The token owner `0xa33a` then uses their private key to sign the hash computed in the previous step using the function
  `var sig = web3.eth.sign(from, signedTransferHash);`.

  The resulting signature is `sig=0xb9195151b7cc53992814d0dc0f15be36f56a0f7e79d0a37f04f2cb4b309320165abdd0eefb5017859e91c84f3225aec2e387daa384de496c71cea8b3e99ecf0c1c`

  This signature can be broken up into 3 parts, r (`sigR`), s (`sigS`) and v (`sigV`):

  * `sigV=0x1c` (last 2 hex chars of signature)
  * `sigR=0xb9195151b7cc53992814d0dc0f15be36f56a0f7e79d0a37f04f2cb4b30932016` (first 64 hex chars of signature)
  * `sigS=0x5abdd0eefb5017859e91c84f3225aec2e387daa384de496c71cea8b3e99ecf0c` (second 64 hex chars of signature)

  The token owner then provides the data `from`, `to`, `tokens`, `fee`, `sigV`, `sigR` and `sigS` plus the function signature and the token
  contract address to the service provider `0xa11a`
* The service provider `0xa11a` can execute the function `var signedTransfer1Check = token.signedTransferCheck(from, to, tokens, fee, nonce, v, r, s);` to check whether the
  following transaction will succeed or fail. In this case, the check returned `signedTransfer1Check=0 Success`
* The service provider `0xa11a` then executes the function `var signedTransfer1Tx = token.signedTransfer(from, to, tokens, fee, nonce, v, r, s, {from: contractOwnerAccount, gas: 200000});`
  and supplies the `from`, `to`, `tokens`, `fee`, `nonce`, `v`, `r` and `s` values originally provided by the token owner `0xa33a`
* The BTTS smart contract function `signedTransfer(...)` will recover the original signing account `0xa33a` from the `v`, `r` and `s` and compare this to
  the `from` account. If the `from` address matches the signing account `0xa33a`, the transfer of tokens can proceed.

  The relevant lines of code from the BTTS smart contract function `signedTransfer(...)` follow:

      // Check owner is the message signer
      bytes32 hash = signedTransferHash(owner, to, tokens, fee, nonce);
      require(owner == ecrecover(keccak256(signingPrefix, hash), v, r, s));

  If the `require(...)` check passes, the BTTS smart contract function `signedTransfer(...)` will execute the transfers. Otherwise the
  transfer fails

* 1 token is transferred from the owner `0xa33a` to the account `0xa55a` - the log of the transfer follows:

      Transfer 0 #2821: from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0 to=0xa55a151eb00fded1634d27d1127b4be4627079ea tokens=1
* 0.01 tokens is transferred from the owner `0xa33a` to the service provider `0xa11a` to compensate the service provider for the 
  ETH transaction fee `costETH=0.001749906 costUSD=0.66564674334` - the log of the transfer follows:

      Transfer 1 #2821: from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0 to=0xa11aae29840fbb5c86e6fd4cf809eba183aef433 tokens=0.01

<br />

Some references on the use of signatures and the `ecrecover(...)` function:

* [Ethereum ecrecover signature verification and encryption](https://ethereum.stackexchange.com/questions/2256/ethereum-ecrecover-signature-verification-and-encryption)
* [workflow on signing a string with private key, followed by signature verification with public key](https://ethereum.stackexchange.com/questions/1777/workflow-on-signing-a-string-with-private-key-followed-by-signature-verificatio)
* [Totally baffled by ecrecover](https://ethereum.stackexchange.com/questions/15364/totally-baffled-by-ecrecover)

<br />

Following are the relevant snippets from the testing script [test/01_test1.sh](test/01_test1.sh) :

```
// -----------------------------------------------------------------------------
var signedTransferMessage = "Signed Transfers";
var from = account3;
var to = account5;
var tokens = new BigNumber("1000000000000000000");
var fee = new BigNumber("10000000000000000");
var nonce = "0";
// -----------------------------------------------------------------------------

console.log("RESULT: " + signedTransferMessage);
console.log("RESULT: from=" + from);
console.log("RESULT: to=" + to);
console.log("RESULT: tokens=" + tokens + " " + tokens.shift(-decimals));
console.log("RESULT: fee=" + fee + " " + fee.shift(-decimals));
console.log("RESULT: nonce=" + nonce);
var signedTransferHash = token.signedTransferHash(from, to, tokens, fee, nonce);
console.log("RESULT: signedTransferHash=" + signedTransferHash);
var sig = web3.eth.sign(from, signedTransferHash);
console.log("RESULT: sig=" + sig);
var r = getSigR(sig);
var s = getSigS(sig);
var v = getSigV(sig);
console.log("RESULT: sigR=" + r);
console.log("RESULT: sigS=" + s);
console.log("RESULT: sigV=" + v);

var signedTransfer1Check = token.signedTransferCheck(from, to, tokens, fee, nonce, v, r, s);
console.log("RESULT: signedTransfer1Check=" + signedTransfer1Check + " " + signedTransferCheckResultString(signedTransfer1Check));
var signedTransfer1Tx = token.signedTransfer(from, to, tokens, fee, nonce, v, r, s,
  {from: contractOwnerAccount, gas: 200000});
while (txpool.status.pending > 0) {
}
printTxData("signedTransfer1Tx", signedTransfer1Tx);
printBalances();
failIfTxStatusError(signedTransfer1Tx, signedTransferMessage + " - Signed Transfer ");
printTokenContractDetails();
console.log("RESULT: ");
```

<br />

Following are the relevant snippets from the testing results [test/test1results.txt](test/test1results.txt) from the execution of the testing script above:

```
Signed Transfers
from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0
to=0xa55a151eb00fded1634d27d1127b4be4627079ea
tokens=1000000000000000000 1
fee=10000000000000000 0.01
nonce=0
signedTransferHash=0xc7e05a63c8b39acaae9a4c0e438f00e30eb69e91d2a960f9dedaea03f662177f
sig=0xb9195151b7cc53992814d0dc0f15be36f56a0f7e79d0a37f04f2cb4b309320165abdd0eefb5017859e91c84f3225aec2e387daa384de496c71cea8b3e99ecf0c1c
sigR=0xb9195151b7cc53992814d0dc0f15be36f56a0f7e79d0a37f04f2cb4b30932016
sigS=0x5abdd0eefb5017859e91c84f3225aec2e387daa384de496c71cea8b3e99ecf0c
sigV=0x1c
signedTransfer1Check=0 Success
signedTransfer1Tx status=0x1 gas=200000 gasUsed=97217 costETH=0.001749906 costUSD=0.66564674334 @ ETH/USD=380.39 gasPrice=18000000000 block=164 txIx=0 txId=0x49b3881b237f3b0e87acc5e2cf49e73674bf5139e79951ec61a370cfaa82d300
 # Account                                             EtherBalanceChange                          Token Name
-- ------------------------------------------ --------------------------- ------------------------------ ---------------------------
 0 0xa00af22d07c87d96eeeb0ed583f8f6ac7812827e       63.063927864000000000           0.000000000000000000 Account #0 - Miner
 1 0xa11aae29840fbb5c86e6fd4cf809eba183aef433       -0.063927864000000000    10000000.010000000000000000 Account #1 - Contract Owner
 2 0xa22ab8a9d641ce77e06d98b7d7065d324d3d6976        0.000000000000000000           0.000000000000000000 Account #2 - Wallet
 3 0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0        0.000000000000000000      999998.990000000000000000 Account #3
 4 0xa44a08d3f6933c69212114bb66e2df1813651844        0.000000000000000000     1000000.000000000000000000 Account #4
 5 0xa55a151eb00fded1634d27d1127b4be4627079ea        0.000000000000000000           1.000000000000000000 Account #5
 6 0xa66a85ede0cbe03694aa9d9de0bb19c99ff55bd9        0.000000000000000000           0.000000000000000000 Account #6
 7 0xa77a2b9d4b1c010a22a7c565dc418cef683dbcec        0.000000000000000000           0.000000000000000000 Account #7
 8 0xb196e7fe3b147dc8421deb884a1fba46cd8e2b63        0.000000000000000000           0.000000000000000000 Lib SafeMath
 9 0x1aa3ebfd892954f32a37b698673505d1dafef4f5        0.000000000000000000           0.000000000000000000 Token 'TST' 'Test'
-- ------------------------------------------ --------------------------- ------------------------------ ---------------------------
                                                                             12000000.000000000000000000 Total Token Balances
-- ------------------------------------------ --------------------------- ------------------------------ ---------------------------

PASS Signed Transfers - Signed Transfer 
tokenContractAddress=0x1aa3ebfd892954f32a37b698673505d1dafef4f5
token.symbol=TST
token.name=Test
token.decimals=18
token.decimalsFactor=1000000000000000000
token.totalSupply=12000000
token.transferable=true
token.mintable=false
Transfer 0 #164: from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0 to=0xa55a151eb00fded1634d27d1127b4be4627079ea tokens=1
Transfer 1 #164: from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0 to=0xa11aae29840fbb5c86e6fd4cf809eba183aef433 tokens=0.01
```

<br />

<hr />

## BTTS Interface

See [contracts/BTTSToken.sol](contracts/BTTSToken.sol) for a sample implementation.

```javascript
// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service (BTTS) Interface v1.00
//
// This consist of the signed message versions of the three ERC20 function:
// - signedTransfer(...)
// - signedApprove(...)
// - signedTransferFrom(...)
//
// Each of these signed message functions have a helper to generate the signed
// message hash:
// - signedTransferHash(...)
// - signedApproveHash(...)
// - signedTransferFromHash(...)
//
// Each of these signed message functions have a help to check the status of
// the signed message before the signed message functions are submitted for
// execution:
// - signedTransferCheck(...)
// - signedApproveCheck(...)
// - signedTransferFromCheck(...)
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSInterface {

    // ------------------------------------------------------------------------
    // Version
    // ------------------------------------------------------------------------
    uint public constant bttsVersion = 100;


    // ------------------------------------------------------------------------
    // signed{X}Check return status
    // ------------------------------------------------------------------------
    enum CheckResult {
        Success,                           // 0 Success
        NotTransferable,                   // 1 Tokens not transferable yet
        SignerMismatch,                    // 2 Mismatch in signing account
        AlreadyExecuted,                   // 3 Transfer already executed
        InsufficientApprovedTokens,        // 4 Insufficient approved tokens
        InsufficientApprovedTokensForFees, // 5 Insufficient approved tokens for fees
        InsufficientTokens,                // 6 Insufficient tokens
        InsufficientTokensForFees,         // 7 Insufficient tokens for fees
        OverflowError                      // 8 Overflow error
    }


    // ------------------------------------------------------------------------
    // signedTransfer functions
    //
    // Generate the hash used to create the signed transfer message
    // ------------------------------------------------------------------------
    function signedTransferHash(address owner, address to, uint tokens,
        uint fee, uint nonce) public view returns (bytes32 hash);

    // ------------------------------------------------------------------------
    // Check whether a transfer can be executed on behalf of the user who
    // signed the transfer message
    // ------------------------------------------------------------------------
    function signedTransferCheck(address owner, address to, uint tokens,
        uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute a transfer on behalf of the user who signed the transfer 
    // message
    // ------------------------------------------------------------------------
    function signedTransfer(address owner, address to, uint tokens, uint fee,
        uint nonce, uint8 v, bytes32 r, bytes32 s)
        public returns (bool success);


    // ------------------------------------------------------------------------
    // signedApprove functions
    //
    // Generate the hash used to create the signed approve message
    // ------------------------------------------------------------------------
    function signedApproveHash(address owner, address spender, uint tokens,
        uint fee, uint nonce) public view returns (bytes32 hash);

    // ------------------------------------------------------------------------
    // Check whether an approve can be executed on behalf of the user who
    // signed the approve message
    // ------------------------------------------------------------------------
    function signedApproveCheck(address owner, address spender, uint tokens,
        uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute an approve on behalf of the user who signed the approve message
    // ------------------------------------------------------------------------
    function signedApprove(address owner, address spender, uint tokens,
        uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public returns (bool success);


    // ------------------------------------------------------------------------
    // signedTransferFrom functions
    //
    // Generate the hash used to create the signed transferFrom message
    // ------------------------------------------------------------------------
    function signedTransferFromHash(address spender, address from, address to,
        uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);

    // ------------------------------------------------------------------------
    // Check whether a transferFrom can be executed on behalf of the user who
    // signed the transferFrom message
    // ------------------------------------------------------------------------
    function signedTransferFromCheck(address spender, address from, address to,
        uint tokens, uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute a transferFrom on behalf of the user who signed the transferFrom 
    // message
    // ------------------------------------------------------------------------
    function signedTransferFrom(address spender, address from, address to,
        uint tokens, uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public returns (bool success);
}
```
<br />

<hr />

## Sample BTTS Implementation

See [contracts/BTTSToken.sol](contracts/BTTSToken.sol) for a sample implementation.

```javascript
// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service (BTTS) Implementation v1.00
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSToken is ERC20Token, BTTSInterface {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Constants used for signing and recovery
    // ------------------------------------------------------------------------
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";

    // ------------------------------------------------------------------------
    // signedTransfer(...) function signature
    // web3.sha3("signedTransfer(address,address,uint256,uint256,uint256,uint8,bytes32,bytes32)").substring(0,10)
    // => "0xa64a9365"
    // ------------------------------------------------------------------------
    bytes4 public constant signedTransferSig = "\xa6\x4a\x93\x65";

    // ------------------------------------------------------------------------
    // signedApprove(...) function signature
    // web3.sha3("signedApprove(address,address,uint256,uint256,uint256,uint8,bytes32,bytes32)").substring(0,10)
    // => "0xb310efc3"
    // ------------------------------------------------------------------------
    bytes4 public constant signedApproveSig = "\xb3\x10\xef\xc3";

    // ------------------------------------------------------------------------
    // signedTransferFrom(...) function signature
    // web3.sha3("signedTransferFrom(address,address,address,uint256,uint256,uint256,uint8,bytes32,bytes32)").substring(0,10)
    // => "0xc6e5df0c"
    // ------------------------------------------------------------------------
    bytes4 public constant signedTransferFromSig = "\xc6\xe5\xdf\x0c";


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function BTTSToken(string _symbol, string _name, uint8 _decimals, 
        uint _initialSupply, bool _mintable, bool _transferable)
        public ERC20Token(_symbol, _name, _decimals, _initialSupply,
        _mintable, _transferable)
    {
    }


    // ------------------------------------------------------------------------
    // signedTransfer functions
    //
    // Generate the hash used to create the signed transfer message
    // ------------------------------------------------------------------------
    function signedTransferHash(address owner, address to, uint tokens,
        uint fee, uint nonce) public view returns (bytes32 hash)
    {
        hash = keccak256(signedTransferSig, address(this), owner, to, tokens,
            fee, nonce);
    }

    // ------------------------------------------------------------------------
    // Check whether a transfer can be executed on behalf of the user who
    // signed the transfer message
    // ------------------------------------------------------------------------
    function signedTransferCheck(address owner, address to, uint tokens,
        uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public constant returns (CheckResult result)
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check owner is the message signer
        bytes32 hash = signedTransferHash(owner, to, tokens, fee, nonce);
        if (owner != ecrecover(keccak256(signingPrefix, hash), v, r, s))
            return CheckResult.SignerMismatch;

        // Check message not already executed
        if (executed[owner][hash]) return CheckResult.AlreadyExecuted;

        uint total = tokens.add(fee);

        // Check there are sufficient tokens to transfer
        if (balances[owner] < tokens) return CheckResult.InsufficientTokens;

        // Check there are sufficient tokens to pay for fees
        if (balances[owner] < total)
            return CheckResult.InsufficientTokensForFees;

        // Check for overflows
        if (balances[to] + tokens < balances[to])
            return CheckResult.OverflowError;
        if (balances[msg.sender] + fee < balances[msg.sender])
            return CheckResult.OverflowError;

        return CheckResult.Success;
    }

    // ------------------------------------------------------------------------
    // Execute a transfer on behalf of the user who signed the transfer
    // message
    // ------------------------------------------------------------------------
    function signedTransfer(address owner, address to, uint tokens, uint fee,
        uint nonce, uint8 v, bytes32 r, bytes32 s)
        public returns (bool success)
    {
        // Check tokens are transferable
        require(transferable);

        // Check owner is the message signer
        bytes32 hash = signedTransferHash(owner, to, tokens, fee, nonce);
        require(owner == ecrecover(keccak256(signingPrefix, hash), v, r, s));

        // Check message not already executed
        require(!executed[owner][hash]);
        executed[owner][hash] = true;

        // Move the tokens and fees
        require(balances[owner] >= tokens);
        balances[owner] = balances[owner].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(owner, to, tokens);

        // Fee
        require(balances[owner] >= fee);
        balances[owner] = balances[owner].sub(fee);
        balances[msg.sender] = balances[msg.sender].add(fee);
        Transfer(owner, msg.sender, fee);

        return true;
    }


    // ------------------------------------------------------------------------
    // signedApprove functions
    //
    // Generate the hash used to create the signed approve message
    // ------------------------------------------------------------------------
    function signedApproveHash(address signer, address spender, uint tokens,
        uint fee, uint nonce) public view returns (bytes32 hash) 
    {
        hash = keccak256(signedApproveSig, address(this),
            signer, spender, tokens, fee, nonce);
    }

    // ------------------------------------------------------------------------
    // Check whether an approve can be executed on behalf of the user who
    // signed the approve message
    // ------------------------------------------------------------------------
    function signedApproveCheck(address owner, address spender, uint tokens,
        uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public constant returns (CheckResult result) 
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check owner is the message signer
        bytes32 hash = signedApproveHash(owner, spender, tokens, fee, nonce);
        if (owner != ecrecover(keccak256(signingPrefix, hash), v, r, s))
            return CheckResult.SignerMismatch;

        // Check message not already executed
        if (executed[owner][hash]) return CheckResult.AlreadyExecuted;

        // Check there are sufficient tokens to pay for fees
        if (balances[owner] < fee)
            return CheckResult.InsufficientTokensForFees;

        // Check for overflows
        if (balances[msg.sender] + fee < balances[msg.sender])
            return CheckResult.OverflowError;

        return CheckResult.Success;
    }

    // ------------------------------------------------------------------------
    // Execute an approve on behalf of the user who signed the approve message
    // ------------------------------------------------------------------------
    function signedApprove(address owner, address spender, uint tokens,
        uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public returns (bool success) 
    {
        // Check tokens are transferable
        require(transferable);

        // Check owner is the message signer
        bytes32 hash = signedApproveHash(owner, spender, tokens, fee, nonce);
        require(owner == ecrecover(keccak256(signingPrefix, hash), v, r, s));

        // Check message not already executed
        require(!executed[owner][hash]);
        executed[owner][hash] = true;

        // Approve
        allowed[owner][spender] = tokens;
        Approval(owner, spender, tokens);

        // Fee
        require(balances[owner] >= fee);
        balances[owner] = balances[owner].sub(fee);
        balances[msg.sender] = balances[msg.sender].add(fee);
        Transfer(owner, msg.sender, fee);

        return true;
    }


    // ------------------------------------------------------------------------
    // signedTransferFrom functions
    //
    // Generate the hash used to create the signed transferFrom message
    // ------------------------------------------------------------------------
    function signedTransferFromHash(address spender, address from, address to,
        uint tokens, uint fee, uint nonce) public view returns (bytes32 hash)
    {
        hash = keccak256(signedTransferFromSig, address(this),
            spender, from, to, tokens, fee, nonce);
    }

    // ------------------------------------------------------------------------
    // Check whether a transferFrom can be executed on behalf of the user who
    // signed the transferFrom message
    // ------------------------------------------------------------------------
    function signedTransferFromCheck(address spender, address from, address to,
        uint tokens, uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public constant returns (CheckResult result)
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check spender is the message signer
        bytes32 hash = signedTransferFromHash(spender, from, to, tokens, fee,
            nonce);
        if (spender != ecrecover(keccak256(signingPrefix, hash), v, r, s))
            return CheckResult.SignerMismatch;

        // Check message not already executed
        if (executed[spender][hash]) return CheckResult.AlreadyExecuted;

        uint total = tokens.add(fee);

        // Check there are sufficient approved tokens to transfer
        if (allowed[from][spender] < tokens)
            return CheckResult.InsufficientApprovedTokens;
        // Check there are sufficient approved tokens to pay for fees
        if (allowed[from][spender] < total)
            return CheckResult.InsufficientApprovedTokensForFees;

        // Check there are sufficient tokens to transfer
        if (balances[from] < tokens) return CheckResult.InsufficientTokens;

        // Check there are sufficient tokens to pay for fees
        if (balances[from] < total)
            return CheckResult.InsufficientTokensForFees;

        // Check for overflows
        if (balances[to] + tokens < balances[to])
            return CheckResult.OverflowError;
        if (balances[msg.sender] + fee < balances[msg.sender])
            return CheckResult.OverflowError;

        return CheckResult.Success;
    }


    // ------------------------------------------------------------------------
    // Execute a transferFrom on behalf of the user who signed the transferFrom 
    // message
    // ------------------------------------------------------------------------
    function signedTransferFrom(address spender, address from, address to,
        uint tokens, uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s)
        public returns (bool success)
    {
        // Check tokens are transferable
        require(transferable);

        // Check spender is the message signer
        bytes32 hash = signedTransferFromHash(spender, from, to, tokens,
            fee, nonce);
        require(spender == ecrecover(keccak256(signingPrefix, hash), v, r, s));

        // Check message not already executed
        require(!executed[spender][hash]);
        executed[spender][hash] = true;

        uint total = tokens.add(fee);
        require(balances[from] >= total);
        require(allowed[from][spender] >= total);

        // Move the tokens and fees
        balances[from] = balances[from].sub(tokens);
        allowed[from][spender] = allowed[from][spender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);

        // Fee
        balances[from] = balances[from].sub(fee);
        allowed[from][spender] = allowed[from][spender].sub(fee);
        balances[msg.sender] = balances[msg.sender].add(fee);
        Transfer(from, msg.sender, fee);

        return true;
    }
```

<br />

<hr />

## Demo On Ropsten Testnet

<br />

<br />


(c) BokkyPooBah / Bok Consulting Pty Ltd - Oct 15 2017. The MIT Licence.
