# BokkyPooBah's Token Teleportation Service Smart Contract

## Summary

[ERC20](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md) token smart contract that
implement the BokkyPooBah's Token Teleportation Service (BTTS) interface provides Ethereum accounts with the ability
to transfer the ERC20 tokens without having to pay for the Ethereum network transaction fees in ethers (ETH).
Instead, the account pays for the token transfer fees in the token being transferred.

#### Account Creates Signed Message

Any ERC20 token contracts that implement the *BTTS Interface* with their own *BTTS Implementation*
will be transferable using this *BTTS Service*. An account holding BTTS enabled tokens use
the implemented functionality to create a message signed with the account's private key with the
token transfer instructions, including the fees specified in the token being transferred.

#### BTTS Service Provider Executes Token Transfer

The account provides the transfer details and the signed message to the *BTTS Service Provider*.
The *BTTS Service Provider* then executes the appropriate function to execute the token transfer,
paying the transaction fees in ETH. On successful execution of the transfer, the fee in tokens will
be transferred to the *BTTS Service Provider*'s account.

The signed message is used to validate the account and parameters for the transfer, and guarantees
that the service provider cannot move more (or less) tokens that the signing account instructed.

#### Use Cases

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
* [History](#history)
* [How It Works](#how-it-works)
* [How Do I Deploy My Own BTTS Token](#how-do-i-deploy-my-own-btts-token)
* [BTTS Interface](#btts-interface)
* [Sample BTTS Implementation](#sample-btts-implementation)
* [Testing](#testing)
* [Code Review](#code-review)

<br />

<hr />

## History

* Dec 10 2017 - Deployed [BTTSTokenFactory.sol v1.00](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/blob/d8806edfea0c2f318dd0262a34c1323df0779220/contracts/BTTSTokenFactory.sol)
  to [0x594dd662b580ca58b1186af45551f34312e91e88](https://etherscan.io/address/0x594dd662b580ca58b1186af45551f34312e91e88#code).
  From this factory, the following BTTSToken contracts were deployed:
  * Dec 10 2017 - GazeCoin token at [0x8c65e992297d5f092a756def24f4781a280198ff](https://etherscan.io/address/0x8c65e992297d5f092a756def24f4781a280198ff#code)
  * Jan 18 2018 - Devery token at [0x923108a439c4e8c2315c4f6521e5ce95b44e9b4c](https://etherscan.io/address/0x923108a439c4e8c2315c4f6521e5ce95b44e9b4c#code)
* Feb 9 2018 - Audit by [Oleksii Matiiasevych](https://github.com/lastperson) identified a major bug
  [#5 Incorrect parameter passed to ApproveAndCallFallBack() function](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/5)
  that would prevent `signedApproveAndCall(...)` from being used correctly
* Feb 11 2018 - [BTTSTokenFactory.sol v1.10](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/blob/ec58bced28ed996cb8cb36bc5783472017fb3689/contracts/BTTSTokenFactory.sol)
  fixes and improvements:
  * **MEDIUM IMPORTANCE** [#5 Incorrect parameter passed to `ApproveAndCallFallBack()` function](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/5)
  * **LOW IMPORTANCE** [#2 Provide function to check account lock status](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/2)
  * **LOW IMPORTANCE** [#3 Get first unused nonce?](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/3)
  * **LOW IMPORTANCE** [#6 Possible reinitialisation to token contract](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/6)
  * **LOW IMPORTANCE** [#7 Remove unnecessary first parameter](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/7)
  * **LOW IMPORTANCE** [#8 Inconsistent return of status](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/8)
  * **LOW IMPORTANCE** [#9 Return style differs from general style](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/9)
  * **LOW IMPORTANCE** [#10 Remove unnecessary parameter](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/10)
  * **LOW IMPORTANCE** [#11 Use of deprecated constant modifier for functions](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/11)
  * **LOW IMPORTANCE** [#12 Store array of deployed tokens in the factory ](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/issues/12)
* Feb 11 2018 - Deployment of [BTTSTokenFactory.sol v1.10](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/blob/ec58bced28ed996cb8cb36bc5783472017fb3689/contracts/BTTSTokenFactory.sol)
  to Ropsten testnet:
  * BTTSLib [0xDb53A3dB5d9224FcE5Ab4459AE008BD2A43Af742](https://ropsten.etherscan.io/address/0xdb53a3db5d9224fce5ab4459ae008bd2a43af742#code) with 3,492,447 gas used
  * BTTSTokenFactory [0xB62Af19795eF9208d368A98bBb0E5B5EB93ed2f3](https://ropsten.etherscan.io/address/0xb62af19795ef9208d368a98bbb0e5b5eb93ed2f3#code) with 3,075,332 gas used
* Feb 11 2018 - Deployment of [BTTSTokenFactory.sol v1.10](https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/blob/ec58bced28ed996cb8cb36bc5783472017fb3689/contracts/BTTSTokenFactory.sol)
  to **Mainnet**:
  * BTTSLib [0x08CeE0ab11fe46E29C539509F25BcBDA2F70e2bF](https://etherscan.io/address/0x08cee0ab11fe46e29c539509f25bcbda2f70e2bf#code) with 3,492,447 gas used
  * BTTSTokenFactory [0x14AabC5adE82240330e5BE05D8ef350661AEbB8a](https://etherscan.io/address/0x14aabc5ade82240330e5be05d8ef350661aebb8a#code) with 3,076,996 gas used
  * The new *GZE* *GazeCoin Metaverse Token* token contract [0x4ac00f287f36a6aad655281fe1ca6798c9cb727b](https://etherscan.io/address/0x4ac00f287f36a6aad655281fe1ca6798c9cb727b#code)
* Feb 20 2018 - Deployment of the *DOLL* *Dollops* BTTSToken v1.10 token contract with 18 decimal places on Ropsten testnet
  [0x362fa7d41a47874cf5231dc12ac7ca1339d1090d](https://ropsten.etherscan.io/token/0x362fa7d41a47874cf5231dc12ac7ca1339d1090d)
  and on Mainnet [0xc3fb4475013ee38099383fbb6893a64579f0bf53](https://etherscan.io/token/0xc3fb4475013ee38099383fbb6893a64579f0bf53)
* Feb 23 2018 - Deployment of the *HOLO* *Hologram* BTTSToken v1.10 token contract with 18 decimal
  places on Mainnet [0x6dd186168874d8741737d6ae8621f7f4c570f16e](https://etherscan.io/token/0x6dd186168874d8741737d6ae8621f7f4c570f16e)
* Feb 24 2018 - Deployment of the *GZERopsten* *GazeCoin Metaverse Token - Ropsten Testnet* BTTSToken v1.10 token contract with 18 decimal
  places on Ropsten testnet [0xa579f55467d230afc54520e6e7f0ceb5ecc3f1a0](https://ropsten.etherscan.io/token/0xa579f55467d230afc54520e6e7f0ceb5ecc3f1a0)

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

## How Do I Deploy My Own BTTS Token

### BTTSTokenFactory Information

On Mainnet, v1.10 of the BTTSTokenFactory has been deployed to [0x14AabC5adE82240330e5BE05D8ef350661AEbB8a](https://etherscan.io/address/0x14aabc5ade82240330e5be05d8ef350661aebb8a#code)
On the Ropsten testnet, v1.10 of the BTTSTokenFactory has been deployed to [0xB62Af19795eF9208d368A98bBb0E5B5EB93ed2f3](https://ropsten.etherscan.io/address/0xb62af19795ef9208d368a98bbb0e5b5eb93ed2f3#code)

The Application Binary Interface for both version follow:

```javascript
[{"constant":false,"inputs":[{"name":"symbol","type":"string"},{"name":"name","type":"string"},{"name":"decimals","type":"uint8"},{"name":"initialSupply","type":"uint256"},{"name":"mintable","type":"bool"},{"name":"transferable","type":"bool"}],"name":"deployBTTSTokenContract","outputs":[{"name":"bttsTokenAddress","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"numberOfDeployedTokens","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenContract","type":"address"}],"name":"verify","outputs":[{"name":"valid","type":"bool"},{"name":"owner","type":"address"},{"name":"decimals","type":"uint256"},{"name":"mintable","type":"bool"},{"name":"transferable","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnershipImmediately","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"tokenAddress","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferAnyERC20Token","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"deployedTokens","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"ownerAddress","type":"address"},{"indexed":true,"name":"bttsTokenAddress","type":"address"},{"indexed":false,"name":"symbol","type":"string"},{"indexed":false,"name":"name","type":"string"},{"indexed":false,"name":"decimals","type":"uint8"},{"indexed":false,"name":"initialSupply","type":"uint256"},{"indexed":false,"name":"mintable","type":"bool"},{"indexed":false,"name":"transferable","type":"bool"}],"name":"BTTSTokenListing","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"}],"name":"OwnershipTransferred","type":"event"}]
```

The methods below show how the BTTSToken can be deployed using the BTTSTokenFactory. Post an issue on this GitHub repository if you cannot
add the verified source code on EtherScan for your new BTTSToken contract.

<br />

### Deploy the BTTSToken from Ethereum Wallet

In Ethereum Wallet / Mist, select the Contracts tab and click on Watch Contract. Enter the following information:

* CONTRACT ADDRESS: `0x14AabC5adE82240330e5BE05D8ef350661AEbB8a`
* CONTRACT NAME: `BTTSTokenFactory`
* JSON INTERFACE: Copy and paste the Application Binary Interface information above
* Click OK

  <kbd><img src="https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/blob/master/images/EthereumWalletWatchBTTSTokenFactory-20180212-112245.png" /></kbd>

Click on the newly created entry "BTTSTOKENFACTORY". Under WRITE TO CONTRACT, select Deploy BTTSToken Contract:

<kbd><img src="https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/blob/master/images/EthereumWalletBTTSTokenFactoryWriteToContract-20180212-112833.png" /></kbd>

Enter the following information:
* Symbol: `{Your token symbol}`
* Name: `{Your token name}`
* Decimals: `{number of decimal places, 0 to 18}`
* Initial supply: `{the initial supply of your tokens}`
* Mintable: `{check the box if you want to deploy and link a minting contract to your token, uncheck the box}`
* Transferable: `{check the box if you want the tokens to be transferable, uncheck otherwise}`
* Execute from: `{select the account that will pay the ETH transaction fees - this will be the owner of the deployed BTTS token}`
* Click EXECUTE and search for the newly deployed BTTSToken by viewing the last transaction from your account:

  <kbd><img src="https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract/blob/master/images/EthereumWalletDeployBTTSTokenContract-20180212-113118.png" /></kbd>

<br />

### Deploy the BTTSToken from Go-Ethereum Command Line

Execute the following instructions from the go-ethereum (`geth`) JavaScript console:

```
var bttsTokenFactoryAbi=[{"constant":false,"inputs":[{"name":"symbol","type":"string"},{"name":"name","type":"string"},{"name":"decimals","type":"uint8"},{"name":"initialSupply","type":"uint256"},{"name":"mintable","type":"bool"},{"name":"transferable","type":"bool"}],"name":"deployBTTSTokenContract","outputs":[{"name":"bttsTokenAddress","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"numberOfDeployedTokens","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"tokenContract","type":"address"}],"name":"verify","outputs":[{"name":"valid","type":"bool"},{"name":"owner","type":"address"},{"name":"decimals","type":"uint256"},{"name":"mintable","type":"bool"},{"name":"transferable","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[],"name":"acceptOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnershipImmediately","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"newOwner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"tokenAddress","type":"address"},{"name":"tokens","type":"uint256"}],"name":"transferAnyERC20Token","outputs":[{"name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"","type":"uint256"}],"name":"deployedTokens","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"ownerAddress","type":"address"},{"indexed":true,"name":"bttsTokenAddress","type":"address"},{"indexed":false,"name":"symbol","type":"string"},{"indexed":false,"name":"name","type":"string"},{"indexed":false,"name":"decimals","type":"uint8"},{"indexed":false,"name":"initialSupply","type":"uint256"},{"indexed":false,"name":"mintable","type":"bool"},{"indexed":false,"name":"transferable","type":"bool"}],"name":"BTTSTokenListing","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"_from","type":"address"},{"indexed":true,"name":"_to","type":"address"}],"name":"OwnershipTransferred","type":"event"}];
var bttsTokenFactoryAddress="0x14AabC5adE82240330e5BE05D8ef350661AEbB8a";
var bttsTokenFactory=eth.contract(bttsTokenFactoryAbi).at(bttsTokenFactoryAddress);

var symbol="MYT";
var name="MyToken";
var decimals=18;
var initialSupply="1000000000000000000000000";
var mintable=false;
var transferable=true;
var fromAccount="{your account}";
var gas=2200000;
var gasPrice=web3.toWei("10", "gwei");
var tx=bttsTokenFactory.deployBTTSTokenContract(symbol, name, decimals, initialSupply, mintable, transferable, {from: fromAccount, gas: gas, gasPrice: gasPrice});
```

Search for the newly deployed BTTSToken by viewing the last transaction from your account.

<br />

<hr />

## BTTS Interface

From [contracts/BTTSTokenFactory.sol](contracts/BTTSTokenFactory.sol), ERC20 tokens that implement the
following interface should be supported by *BTTS Service Providers*:

```javascript
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service Interface v1.10
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSTokenInterface is ERC20Interface {
    uint public constant bttsVersion = 110;

    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";

    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event Mint(address indexed tokenOwner, uint tokens, bool lockAccount);
    event MintingDisabled();
    event TransfersEnabled();
    event AccountUnlocked(address indexed tokenOwner);

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);

    // ------------------------------------------------------------------------
    // signed{X} functions
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result);
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function mint(address tokenOwner, uint tokens, bool lockAccount) public returns (bool success);
    function unlockAccount(address tokenOwner) public;
    function disableMinting() public;
    function enableTransfers() public;

    // ------------------------------------------------------------------------
    // signed{X}Check return status
    // ------------------------------------------------------------------------
    enum CheckResult {
        Success,                           // 0 Success
        NotTransferable,                   // 1 Tokens not transferable yet
        AccountLocked,                     // 2 Account locked
        SignerMismatch,                    // 3 Mismatch in signing account
        InvalidNonce,                      // 4 Invalid nonce
        InsufficientApprovedTokens,        // 5 Insufficient approved tokens
        InsufficientApprovedTokensForFees, // 6 Insufficient approved tokens for fees
        InsufficientTokens,                // 7 Insufficient tokens
        InsufficientTokensForFees,         // 8 Insufficient tokens for fees
        OverflowError                      // 9 Overflow error
    }
}
```
<br />

<hr />

## Sample BTTS Implementation

From [contracts/BTTSTokenFactory.sol](contracts/BTTSTokenFactory.sol) the main parts of the BTTS functionality follow:

```javascript
// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service Library v1.00
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
library BTTSLib {
    struct Data {
        bool initialised;

        // Ownership
        address owner;
        address newOwner;

        // Minting and management
        address minter;
        bool mintable;
        bool transferable;
        mapping(address => bool) accountLocked;

        // Token
        string symbol;
        string name;
        uint8 decimals;
        uint totalSupply;
        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;
        mapping(address => uint) nextNonce;
    }

    ...

    // ------------------------------------------------------------------------
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // The signature format is a compact form {bytes32 r}{bytes32 s}{uint8 v}.
    // Compact means, uint8 is not padded to 32 bytes.
    //
    // An invalid signature results in the address(0) being returned, make
    // sure that the returned result is checked to be non-zero for validity
    //
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(bytes32 hash, bytes sig) public pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP, one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change, see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }

    ...

    // ------------------------------------------------------------------------
    // Signed function
    // ------------------------------------------------------------------------
    function signedTransferHash(Data storage /*self*/, address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(signedTransferSig, address(this), tokenOwner, to, tokens, fee, nonce);
    }
    function signedTransferCheck(Data storage self, address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (BTTSTokenInterface.CheckResult result) {
        if (!self.transferable) return BTTSTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedTransferHash(self, tokenOwner, to, tokens, fee, nonce);
        if (tokenOwner == address(0) || tokenOwner != ecrecoverFromSig(keccak256(signingPrefix, hash), sig)) return BTTSTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[tokenOwner]) return BTTSTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[tokenOwner] != nonce) return BTTSTokenInterface.CheckResult.InvalidNonce;
        uint total = safeAdd(tokens, fee);
        if (self.balances[tokenOwner] < tokens) return BTTSTokenInterface.CheckResult.InsufficientTokens;
        if (self.balances[tokenOwner] < total) return BTTSTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[to] + tokens < self.balances[to]) return BTTSTokenInterface.CheckResult.OverflowError;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return BTTSTokenInterface.CheckResult.OverflowError;
        return BTTSTokenInterface.CheckResult.Success;
    }
    function signedTransfer(Data storage self, address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedTransferHash(self, tokenOwner, to, tokens, fee, nonce);
        require(tokenOwner != address(0) && tokenOwner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));
        require(!self.accountLocked[tokenOwner]);
        require(self.nextNonce[tokenOwner] == nonce);
        self.nextNonce[tokenOwner] = nonce + 1;
        self.balances[tokenOwner] = safeSub(self.balances[tokenOwner], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        Transfer(tokenOwner, to, tokens);
        self.balances[tokenOwner] = safeSub(self.balances[tokenOwner], fee);
        self.balances[feeAccount] = safeAdd(self.balances[feeAccount], fee);
        Transfer(tokenOwner, feeAccount, fee);
        return true;
    }
    function signedApproveHash(Data storage /*self*/, address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(signedApproveSig, address(this), tokenOwner, spender, tokens, fee, nonce);
    }
    function signedApproveCheck(Data storage self, address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (BTTSTokenInterface.CheckResult result) {
        if (!self.transferable) return BTTSTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedApproveHash(self, tokenOwner, spender, tokens, fee, nonce);
        if (tokenOwner == address(0) || tokenOwner != ecrecoverFromSig(keccak256(signingPrefix, hash), sig)) return BTTSTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[tokenOwner]) return BTTSTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[tokenOwner] != nonce) return BTTSTokenInterface.CheckResult.InvalidNonce;
        if (self.balances[tokenOwner] < fee) return BTTSTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return BTTSTokenInterface.CheckResult.OverflowError;
        return BTTSTokenInterface.CheckResult.Success;
    }
    function signedApprove(Data storage self, address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedApproveHash(self, tokenOwner, spender, tokens, fee, nonce);
        require(tokenOwner != address(0) && tokenOwner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));
        require(!self.accountLocked[tokenOwner]);
        require(self.nextNonce[tokenOwner] == nonce);
        self.nextNonce[tokenOwner] = nonce + 1;
        self.allowed[tokenOwner][spender] = tokens;
        Approval(tokenOwner, spender, tokens);
        self.balances[tokenOwner] = safeSub(self.balances[tokenOwner], fee);
        self.balances[feeAccount] = safeAdd(self.balances[feeAccount], fee);
        Transfer(tokenOwner, feeAccount, fee);
        return true;
    }
    function signedTransferFromHash(Data storage /*self*/, address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(signedTransferFromSig, address(this), spender, from, to, tokens, fee, nonce);
    }
    function signedTransferFromCheck(Data storage self, address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (BTTSTokenInterface.CheckResult result) {
        if (!self.transferable) return BTTSTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedTransferFromHash(self, spender, from, to, tokens, fee, nonce);
        if (spender == address(0) || spender != ecrecoverFromSig(keccak256(signingPrefix, hash), sig)) return BTTSTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[from]) return BTTSTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[spender] != nonce) return BTTSTokenInterface.CheckResult.InvalidNonce;
        uint total = safeAdd(tokens, fee);
        if (self.allowed[from][spender] < tokens) return BTTSTokenInterface.CheckResult.InsufficientApprovedTokens;
        if (self.allowed[from][spender] < total) return BTTSTokenInterface.CheckResult.InsufficientApprovedTokensForFees;
        if (self.balances[from] < tokens) return BTTSTokenInterface.CheckResult.InsufficientTokens;
        if (self.balances[from] < total) return BTTSTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[to] + tokens < self.balances[to]) return BTTSTokenInterface.CheckResult.OverflowError;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return BTTSTokenInterface.CheckResult.OverflowError;
        return BTTSTokenInterface.CheckResult.Success;
    }
    function signedTransferFrom(Data storage self, address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedTransferFromHash(self, spender, from, to, tokens, fee, nonce);
        require(spender != address(0) && spender == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));
        require(!self.accountLocked[from]);
        require(self.nextNonce[spender] == nonce);
        self.nextNonce[spender] = nonce + 1;
        self.balances[from] = safeSub(self.balances[from], tokens);
        self.allowed[from][spender] = safeSub(self.allowed[from][spender], tokens);
        self.balances[to] = safeAdd(self.balances[to], tokens);
        Transfer(from, to, tokens);
        self.balances[from] = safeSub(self.balances[from], fee);
        self.allowed[from][spender] = safeSub(self.allowed[from][spender], fee);
        self.balances[feeAccount] = safeAdd(self.balances[feeAccount], fee);
        Transfer(from, feeAccount, fee);
        return true;
    }
    function signedApproveAndCallHash(Data storage /*self*/, address tokenOwner, address spender, uint tokens, bytes data, uint fee, uint nonce) public view returns (bytes32 hash) {
        hash = keccak256(signedApproveAndCallSig, address(this), tokenOwner, spender, tokens, data, fee, nonce);
    }
    function signedApproveAndCallCheck(Data storage self, address tokenOwner, address spender, uint tokens, bytes data, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (BTTSTokenInterface.CheckResult result) {
        if (!self.transferable) return BTTSTokenInterface.CheckResult.NotTransferable;
        bytes32 hash = signedApproveAndCallHash(self, tokenOwner, spender, tokens, data, fee, nonce);
        if (tokenOwner == address(0) || tokenOwner != ecrecoverFromSig(keccak256(signingPrefix, hash), sig)) return BTTSTokenInterface.CheckResult.SignerMismatch;
        if (self.accountLocked[tokenOwner]) return BTTSTokenInterface.CheckResult.AccountLocked;
        if (self.nextNonce[tokenOwner] != nonce) return BTTSTokenInterface.CheckResult.InvalidNonce;
        if (self.balances[tokenOwner] < fee) return BTTSTokenInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return BTTSTokenInterface.CheckResult.OverflowError;
        return BTTSTokenInterface.CheckResult.Success;
    }
    function signedApproveAndCall(Data storage self, address tokenOwner, address spender, uint tokens, bytes data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedApproveAndCallHash(self, tokenOwner, spender, tokens, data, fee, nonce);
        require(tokenOwner != address(0) && tokenOwner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));
        require(!self.accountLocked[tokenOwner]);
        require(self.nextNonce[tokenOwner] == nonce);
        self.nextNonce[tokenOwner] = nonce + 1;
        self.allowed[tokenOwner][spender] = tokens;
        Approval(tokenOwner, spender, tokens);
        self.balances[tokenOwner] = safeSub(self.balances[tokenOwner], fee);
        self.balances[feeAccount] = safeAdd(self.balances[feeAccount], fee);
        Transfer(tokenOwner, feeAccount, fee);
        ApproveAndCallFallBack(spender).receiveApproval(tokenOwner, tokens, address(this), data);
        return true;
    }
}

...

// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service Token Factory v1.00
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSToken is BTTSTokenInterface {
    using BTTSLib for BTTSLib.Data;

    BTTSLib.Data data;

    ...

    // ------------------------------------------------------------------------
    // Signed function
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedTransferHash(tokenOwner, to, tokens, fee, nonce);
    }
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result) {
        return data.signedTransferCheck(tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        return data.signedTransfer(tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }
    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedApproveHash(tokenOwner, spender, tokens, fee, nonce);
    }
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result) {
        return data.signedApproveCheck(tokenOwner, spender, tokens, fee, nonce, sig, feeAccount);
    }
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        return data.signedApprove(tokenOwner, spender, tokens, fee, nonce, sig, feeAccount);
    }
    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedTransferFromHash(spender, from, to, tokens, fee, nonce);
    }
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result) {
        return data.signedTransferFromCheck(spender, from, to, tokens, fee, nonce, sig, feeAccount);
    }
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        return data.signedTransferFrom(spender, from, to, tokens, fee, nonce, sig, feeAccount);
    }
    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedApproveAndCallHash(tokenOwner, spender, tokens, _data, fee, nonce);
    }
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public view returns (CheckResult result) {
        return data.signedApproveAndCallCheck(tokenOwner, spender, tokens, _data, fee, nonce, sig, feeAccount);
    }
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        return data.signedApproveAndCall(tokenOwner, spender, tokens, _data, fee, nonce, sig, feeAccount);
    }
}
```

<br />

<hr />

## Testing

Details of the testing environment can be found in [test](test).

The following functions were tested using the script [test/01_test1.sh](test/01_test1.sh) with the summary results saved
in [test/test1results.txt](test/test1results.txt) and the detailed output saved in [test/test1output.txt](test/test1output.txt):

* [x] Deploy test ApproveAndCallFallBack contract
* [x] Deploy BTTS library
* [x] Deploy BTTSTokenFactory contract
* [x] Deploy BTTSToken contract using BTTSTokenFactory
* [x] Mint tokens for accounts 3 and 4 with tokens locked
* [x] Disable minting and enable transfers
* [x] Unlock tokens for accounts 3 and 4
* [x] Execute a `signedTransfer(...)` and check that a duplicate fails
* [x] Execute a `signedApprove(...)` and check that a duplicate fails
* [x] Execute a `signedTransferFrom(...)` and check that a duplicate fails
* [x] Execute a `signedApproveAndCall(...)` and check that a duplicate fails
* [x] Execute `transfer(...)`'s
* [x] Execute a `approveAndCall(...)`
* [x] Execute `transfer(...)` and `transferFrom(...)` of 0 tokens
* [x] Execute `transfer(...)`, `approve(...)` and `transferFrom(...)` for more tokens that owned, expecting failure
* [x] Execute `approve(...)` to change a non-0 allowance

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

<br />


(c) BokkyPooBah / Bok Consulting Pty Ltd - Feb 11 2018. The MIT Licence.
