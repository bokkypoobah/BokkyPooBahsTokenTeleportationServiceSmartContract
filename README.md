# BokkyPooBah's Token Teleportation Service Smart Contract

## Mainnet Deployment

* BTTSTokenFactory: [0x594dd662b580ca58b1186af45551f34312e91e88](https://etherscan.io/address/0x594dd662b580ca58b1186af45551f34312e91e88#code)
* GazeCoin token: [0x8c65e992297d5f092a756def24f4781a280198ff](https://etherscan.io/address/0x8c65e992297d5f092a756def24f4781a280198ff#code)
* Devery token: [0x923108a439c4e8c2315c4f6521e5ce95b44e9b4c](https://etherscan.io/address/0x923108a439c4e8c2315c4f6521e5ce95b44e9b4c#code)

<br />

<hr />

## Summary

ERC20 token smart contract that implement the BokkyPooBah's Token Teleportation Service (BTTS)
interface provides Ethereum accounts with the ability to transfer the ERC20 tokens without 
having to pay for the Ethereum network transaction fees in ethers (ETH). Instead, the account
pays for the token transfer fees in the token being transferred.

<br />

### Account Creates Signed Message

Any ERC20 token contracts that implement the *BTTS Interface* with their own *BTTS Implementation*
will be transferable using this *BTTS Service*. An account holding BTTS enabled tokens use
the implemented functionality to create a message signed with the account's private key with the
token transfer instructions, including the fees specified in the token being transferred.

<br />

### BTTS Service Provider Executes Token Transfer

The account provides the transfer details and the signed message to the *BTTS Service Provider*.
The *BTTS Service Provider* then executes the appropriate function to execute the token transfer,
paying the transaction fees in ETH. On successful execution of the transfer, the fee in tokens will
be transferred to the *BTTS Service Provider*'s account.

The signed message is used to validate the account and parameters for the transfer, and guarantees
that the service provider cannot move more (or less) tokens that the signing account instructed.

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
* [Code Review](#code-review)
* [Demo On Ropsten Testnet](#demo-on-ropsten-testnet)

<br />

<hr />

## How It Works

This example will explain the results from the testing script and testing results. Note that the computed
hashes will differ in the testing results because new token contract addresses are created in each testing
session.

In the testing [script](test/01_test1.sh) and [results](test/test1results.txt):

* The account `0xa33a` wants to transfer 1 token to account `0xa55a` and pay a 0.01 token fee 
* The parameters for the signed transfers are:
  * `from` = `0xa33a`
  * `to` = `0xa55a`
  * `tokens` = `1` or the natural number 1000000000000000000 with 18 decimal places
  * `fee` = `0.01` or the natural number 10000000000000000 with 18 decimal places
  * `nonce` = `0` - this is an incrementing number for each new transaction
* The account `0xa33a` creates a hash of the parameters above, and in addition includes:
  * `functionSig` = `0x7532eaac` - this is the same function signature scheme that Ethereum uses
  * token contract address = `0xa1b42c6ad2e1d69eee56532557480c20697aa3b5`
* The hash of the parameters is calculated using `var signedTransferHash = token.signedTransferHash(from, to, tokens, fee, nonce);`

  Here is the function:

      function signedTransferHash(address tokenOwner, address to, uint tokens,
          uint fee, uint nonce) public view returns (bytes32 hash)
      {
          hash = keccak256(signedTransferSig, address(this), tokenOwner, to,
              tokens, fee, nonce);
      }

* The hash of the parameters can also be manually constructed using:

  > var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(from) + addressToHex(to) + uint256ToHex(tokens) + uint256ToHex(fee) + uint256ToHex(nonce);

* Any small difference in the parameters will result in a totally different hash
* In this example, the hash is computed to be `0x8ffe42d6c4bbfb872eed6996414cf6d0084a701c0b8681573c8f75989ee1ce0a`
* The token owner `0xa33a` then uses their private key to sign the hash computed in the previous step using the function
  `var sig = web3.eth.sign(from, signedTransferHash);`.

  The resulting signature is `sig=0xd563e5d5e0ace9e2f6ebc11fd7f2888a9289cdf9e2e44a148a72a14cc3a77c445e35d8abdbd499779c7d2d5081785beee092de14c7dcc6dc6e2aa653f3b4d1d51b`

  The token owner then provides the data `from`, `to`, `tokens`, `fee`, `sig` plus the function signature and the token contract address to the service provider `0xa11a`
* The service provider `0xa11a` can then execute the function `var signedTransfer1Check = token.signedTransferCheck(from, to, tokens, fee, nonce, sig, feeAccount);` to check
  whether the `signedTransfer(...)` function will succeed or fail if executed. In this case, the check returned `signedTransfer1Check=0 Success`
* The service provider `0xa11a` then executes the function `var signedTransfer1Tx = token.signedTransfer(from, to, tokens, fee, nonce, sig, feeAccount, {from: contractOwnerAccount, gas: 200000});`
  and supplies the `from`, `to`, `tokens`, `fee`, `nonce`, `sig` values originally provided by the token owner `0xa33a`. The service provider also nominates their `feeAccount`
* The BTTS smart contract function `signedTransfer(...)` will recover the original signing account `0xa33a` from the hash of the parameters and supplied signature, and compare this to
  the `from` account. If the `from` address matches the signing account `0xa33a`, the transfer of tokens can proceed.

  The relevant lines of code from the BTTS smart contract function `signedTransfer(...)` follow:

      // Check owner is the message signer
      bytes32 hash = signedTransferHash(owner, to, tokens, fee, nonce);
      require(owner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

  If `ecrecoverFromSig(...)` returnes the same account as the token holder, the `require(...)` check passes. BTTS smart contract function `signedTransfer(...)` will continue executing
  the transfers. If any of the parameters are not exactly the same parameters using the the hashing and signing process, `ecrecoverFromSig(...)` will return a different account to 
  the token holder account.

* 1 token is transferred from the owner `0xa33a` to the account `0xa55a` - the log of the transfer follows:

      Transfer 0 #166: from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0 to=0xa55a151eb00fded1634d27d1127b4be4627079ea tokens=1
* 0.01 tokens is transferred from the owner `0xa33a` to the service provider `0xa11a` to compensate the service provider for the 
  ETH transaction fee `costETH=0.001749906 costUSD=0.66564674334` - the log of the transfer follows:

      Transfer 1 #166: from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0 to=0xa88a05d2b88283ce84c8325760b72a64591279a2 tokens=0.01

<br />

Some references on the use of signatures and the `ecrecover(...)` function:

* [Ethereum ecrecover signature verification and encryption](https://ethereum.stackexchange.com/questions/2256/ethereum-ecrecover-signature-verification-and-encryption)
* [workflow on signing a string with private key, followed by signature verification with public key](https://ethereum.stackexchange.com/questions/1777/workflow-on-signing-a-string-with-private-key-followed-by-signature-verificatio)
* [Totally baffled by ecrecover](https://ethereum.stackexchange.com/questions/15364/totally-baffled-by-ecrecover)

In Solidity, the `ecrecover(....)` function takes the signature as 3 separate parts - r (`sigR`), s (`sigS`) and v (`sigV`).

The signature `0xd563e5d5e0ace9e2f6ebc11fd7f2888a9289cdf9e2e44a148a72a14cc3a77c445e35d8abdbd499779c7d2d5081785beee092de14c7dcc6dc6e2aa653f3b4d1d51b` can be broken into the 3 parts:

  * `sigV=0x1b` (last 2 hex chars of signature)
  * `sigR=d563e5d5e0ace9e2f6ebc11fd7f2888a9289cdf9e2e44a148a72a14cc3a77c44` (first 64 hex chars of signature)
  * `sigS=5e35d8abdbd499779c7d2d5081785beee092de14c7dcc6dc6e2aa653f3b4d1d5` (second 64 hex chars of signature)
  
The `ecrecoverFromSig(...)` is supplied with the full length signature, splits the full length signature into the component [v, r, s] and calls the `ecrecover(...)` function

<br />

Following are the relevant snippets from the testing script [test/01_test1.sh](test/01_test1.sh) :

```
// -----------------------------------------------------------------------------
var signedTransferMessage = "Signed Transfers";
var from = account3;
var to = account5;
var tokens = new BigNumber("1000000000000000000");
var fee = new BigNumber("10000000000000000");
var feeToken = token;
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

var signedTransfer1Check = token.signedTransferCheck(from, to, tokens, fee, nonce, sig, feeAccount);
console.log("RESULT: signedTransfer1Check=" + signedTransfer1Check + " " + signedTransferCheckResultString(signedTransfer1Check));
var signedTransfer1Tx = token.signedTransfer(from, to, tokens, fee, nonce, sig, feeAccount, 
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
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
signedTransferHash=0x8ffe42d6c4bbfb872eed6996414cf6d0084a701c0b8681573c8f75989ee1ce0a
sig=0xd563e5d5e0ace9e2f6ebc11fd7f2888a9289cdf9e2e44a148a72a14cc3a77c445e35d8abdbd499779c7d2d5081785beee092de14c7dcc6dc6e2aa653f3b4d1d51b
signedTransfer1Check=0 Success
signedTransfer1Tx status=0x1 Success gas=200000 gasUsed=99336 costETH=0.000099336 costUSD=0.030567773256 @ ETH/USD=307.721 gasPrice=1 gwei block=166 txIx=0 txId=0xce11bafd68777e44964716daed0801948a0466b22c549f1fea7a1cae47dcb4c3
 # Account                                             EtherBalanceChange                          Token Name
-- ------------------------------------------ --------------------------- ------------------------------ ---------------------------
 0 0xa00af22d07c87d96eeeb0ed583f8f6ac7812827e       84.010982023000000000           0.000000000000000000 Account #0 - Miner
 1 0xa11aae29840fbb5c86e6fd4cf809eba183aef433       -0.010982023000000000    10000000.000000000000000000 Account #1 - Contract Owner
 2 0xa22ab8a9d641ce77e06d98b7d7065d324d3d6976        0.000000000000000000           0.000000000000000000 Account #2 - Wallet
 3 0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0        0.000000000000000000      999998.980000000000000000 Account #3
 4 0xa44a08d3f6933c69212114bb66e2df1813651844        0.000000000000000000     1000000.000000000000000000 Account #4
 5 0xa55a151eb00fded1634d27d1127b4be4627079ea        0.000000000000000000           1.000000000000000000 Account #5
 6 0xa66a85ede0cbe03694aa9d9de0bb19c99ff55bd9        0.000000000000000000           0.000000000000000000 Account #6
 7 0xa77a2b9d4b1c010a22a7c565dc418cef683dbcec        0.000000000000000000           0.000000000000000000 Account #7
 8 0xa88a05d2b88283ce84c8325760b72a64591279a2        0.000000000000000000           0.020000000000000000 Fee Account
 9 0x545b861c70089afcbee7c3e8ff00e1ab9e5be210        0.000000000000000000           0.000000000000000000 Lib SafeMath
10 0xb3c7d39fdd2e7dcd02b660b1a317ae06c7c915cc        0.000000000000000000           0.000000000000000000 BTTSTokenFactory
11 0xa1b42c6ad2e1d69eee56532557480c20697aa3b5        0.000000000000000000           0.000000000000000000 Token 'GZETest' 'GazeCoin Test'
-- ------------------------------------------ --------------------------- ------------------------------ ---------------------------
                                                                             12000000.000000000000000000 Total Token Balances
-- ------------------------------------------ --------------------------- ------------------------------ ---------------------------

PASS Signed Transfers - Signed Transfer 
tokenContractAddress=0xa1b42c6ad2e1d69eee56532557480c20697aa3b5
token.owner=0xa11aae29840fbb5c86e6fd4cf809eba183aef433
token.newOwner=0x0000000000000000000000000000000000000000
token.symbol=GZETest
token.name=GazeCoin Test
token.decimals=18
token.decimalsFactor=1000000000000000000
token.totalSupply=12000000
token.transferable=true
token.mintable=false
token.minter=0x0000000000000000000000000000000000000000
Transfer 0 #166: from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0 to=0xa55a151eb00fded1634d27d1127b4be4627079ea tokens=1
Transfer 1 #166: from=0xa33a6c312d9ad0e0f2e95541beed0cc081621fd0 to=0xa88a05d2b88283ce84c8325760b72a64591279a2 tokens=0.01
```

<br />

<hr />

## BTTS Interface

See [contracts/BTTSToken100.sol](contracts/BTTSToken100.sol) for a sample implementation.

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

## Code Review

* [x] [code-review/BTTSTokenFactory.md](code-review/BTTSTokenFactory.md)
  * [x] contract ERC20Interface
  * [x] contract ApproveAndCallFallBack
  * [x] contract BTTSTokenInterface is ERC20Interface
  * [x] library BTTSLib
  * [x] contract BTTSToken is BTTSTokenInterface
  * [x] contract Owned
  * [x] contract BTTSTokenFactory is Owned

<br />

<hr />

## Demo On Ropsten Testnet

Later on.

<br />

<br />


(c) BokkyPooBah / Bok Consulting Pty Ltd - Nov 18 2017. The MIT Licence.
