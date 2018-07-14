#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

SOURCEDIR=`grep ^SOURCEDIR= settings.txt | sed "s/^.*=//"`

TOKENFACTORYSOL=`grep ^TOKENFACTORYSOL= settings.txt | sed "s/^.*=//"`
TOKENFACTORYJS=`grep ^TOKENFACTORYJS= settings.txt | sed "s/^.*=//"`
TESTSOL=`grep ^TESTSOL= settings.txt | sed "s/^.*=//"`
TESTJS=`grep ^TESTJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

if [ "$MODE" == "dev" ]; then
  # Start time now
  STARTTIME=`echo "$CURRENTTIME" | bc`
else
  # Start time 1m 10s in the future
  STARTTIME=`echo "$CURRENTTIME+90" | bc`
fi
STARTTIME_S=`date -r $STARTTIME -u`
ENDTIME=`echo "$CURRENTTIME+60*3" | bc`
ENDTIME_S=`date -r $ENDTIME -u`

printf "MODE            = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD        = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "SOURCEDIR       = '$SOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "TOKENFACTORYSOL = '$TOKENFACTORYSOL'\n" | tee -a $TEST1OUTPUT
printf "TOKENFACTORYJS  = '$TOKENFACTORYJS'\n" | tee -a $TEST1OUTPUT
printf "TESTSOL         = '$TESTSOL'\n" | tee -a $TEST1OUTPUT
printf "TESTJS          = '$TESTJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA  = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS       = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT     = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS    = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME     = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "STARTTIME       = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST1OUTPUT
printf "ENDTIME         = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
# `cp modifiedContracts/SnipCoin.sol .`
`cp $SOURCEDIR/$TOKENFACTORYSOL .`
`cp $SOURCEDIR/$TESTSOL .`

# --- Modify parameters ---
# `perl -pi -e "s/bool transferable/bool public transferable/" $TOKENSOL`

DIFFS1=`diff $SOURCEDIR/$TOKENFACTORYSOL $TOKENFACTORYSOL`
echo "--- Differences $SOURCEDIR/$TOKENFACTORYSOL $TOKENFACTORYSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

solc_0.4.18 --version | tee -a $TEST1OUTPUT

echo "var tokenFactoryOutput=`solc_0.4.18 --optimize --pretty-json --combined-json abi,bin,interface $TOKENFACTORYSOL`;" > $TOKENFACTORYJS
echo "var testOutput=`solc_0.4.18 --optimize --pretty-json --combined-json abi,bin,interface $TESTSOL`;" > $TESTJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$TOKENFACTORYJS");
loadScript("$TESTJS");
loadScript("functions.js");
loadScript("bttsHelperFunctions.js");

var libBTTSAbi = JSON.parse(tokenFactoryOutput.contracts["$TOKENFACTORYSOL:BTTSLib"].abi);
var libBTTSBin = "0x" + tokenFactoryOutput.contracts["$TOKENFACTORYSOL:BTTSLib"].bin;
var tokenAbi = JSON.parse(tokenFactoryOutput.contracts["$TOKENFACTORYSOL:BTTSToken"].abi);
var tokenBin = "0x" + tokenFactoryOutput.contracts["$TOKENFACTORYSOL:BTTSToken"].bin;
var factoryAbi = JSON.parse(tokenFactoryOutput.contracts["$TOKENFACTORYSOL:BTTSTokenFactory"].abi);
var factoryBin = "0x" + tokenFactoryOutput.contracts["$TOKENFACTORYSOL:BTTSTokenFactory"].bin;
var testAbi = JSON.parse(testOutput.contracts["$TESTSOL:TestApproveAndCallFallBack"].abi);
var testBin = "0x" + testOutput.contracts["$TESTSOL:TestApproveAndCallFallBack"].bin;

// console.log("DATA: libBTTSAbi=" + JSON.stringify(libBTTSAbi));
// console.log("DATA: libBTTSBin=" + JSON.stringify(libBTTSBin));
// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));
// console.log("DATA: factoryAbi=" + JSON.stringify(factoryAbi));
// console.log("DATA: factoryBin=" + JSON.stringify(factoryBin));
// console.log("DATA: testAbi=" + JSON.stringify(testAbi));
// console.log("DATA: testBin=" + JSON.stringify(testBin));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployTestMessage = "Deploy Test ApproveAndCallFallBack Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + deployTestMessage + " ---");
var testContract = web3.eth.contract(testAbi);
// console.log(JSON.stringify(testContract));
var testTx = null;
var testAddress = null;
var test = testContract.new({from: contractOwnerAccount, data: testBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        testTx = contract.transactionHash;
      } else {
        testAddress = contract.address;
        addAccount(testAddress, "Test ApproveAndCallFallBack");
        addTestContractAddressAndAbi(testAddress, testAbi);
        console.log("DATA: testAddress=" + testAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(testTx, deployTestMessage);
printTxData("testTx", testTx);
printTestContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployLibBTTSMessage = "Deploy BTTS Library";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + deployLibBTTSMessage + " ---");
var libBTTSContract = web3.eth.contract(libBTTSAbi);
// console.log(JSON.stringify(libBTTSContract));
var libBTTSTx = null;
var libBTTSAddress = null;
var libBTTS = libBTTSContract.new({from: contractOwnerAccount, data: libBTTSBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        libBTTSTx = contract.transactionHash;
      } else {
        libBTTSAddress = contract.address;
        addAccount(libBTTSAddress, "BTTS Library");
        console.log("DATA: libBTTSAddress=" + libBTTSAddress);
      }
    }
  }
);
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(libBTTSTx, deployLibBTTSMessage);
printTxData("libBTTSTx", libBTTSTx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployFactoryMessage = "Deploy BTTSTokenFactory";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + deployFactoryMessage + " ---");
// console.log("RESULT: old='" + factoryBin + "'");
var newFactoryBin = factoryBin.replace(/__BTTSTokenFactory.sol:BTTSLib__________/g, libBTTSAddress.substring(2, 42));
// console.log("RESULT: new='" + newFactoryBin + "'");

var factoryContract = web3.eth.contract(factoryAbi);
// console.log(JSON.stringify(factoryAbi));
// console.log(factoryBin);
var factoryTx = null;
var factoryAddress = null;

var factory = factoryContract.new({from: contractOwnerAccount, data: newFactoryBin, gas: 6000000, gasPrice: defaultGasPrice},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        factoryTx = contract.transactionHash;
      } else {
        factoryAddress = contract.address;
        addAccount(factoryAddress, "BTTSTokenFactory");
        addFactoryContractAddressAndAbi(factoryAddress, factoryAbi);
        console.log("DATA: factoryAddress=" + factoryAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printBalances();
failIfTxStatusError(factoryTx, deployFactoryMessage);
printTxData("factoryTx", factoryTx);
printFactoryContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var tokenMessage = "Deploy Token Contract";
// console.log("RESULT: old='" + tokenBin + "'");
// var newTokenBin = tokenBin.replace(/__BTTSToken100\.sol\:SafeMath_____________/g, libAddress.substring(2, 42));
// console.log("RESULT: new='" + newTokenBin + "'");
var symbol = "GZETest";
var name = "GazeCoin Test";
var decimals = 18;
var initialSupply = "10000000000000000000000000";
var mintable = true;
var transferable = false;
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + tokenMessage + " ---");
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;
var deployTokenTx = factory.deployBTTSTokenContract(symbol, name, decimals, initialSupply, mintable, transferable, {from: contractOwnerAccount, gas: 4000000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var bttsTokens = getBTTSFactoryTokenListing();
console.log("RESULT: bttsTokens=#" + bttsTokens.length + " " + JSON.stringify(bttsTokens));
// Can check, but the rest will not work anyway - if (bttsTokens.length == 1)
tokenAddress = bttsTokens[0];
token = web3.eth.contract(tokenAbi).at(tokenAddress);
// console.log("RESULT: token=" + JSON.stringify(token));
addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
printBalances();
printTxData("deployTokenTx", deployTokenTx);
printFactoryContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var mintTokensMessage = "Mint Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + mintTokensMessage + " ---");
var mintTokens1Tx = token.mint(account3, "1000000000000000000000000", true, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var mintTokens2Tx = token.mint(account4, "1000000000000000000000000", true, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(mintTokens1Tx, mintTokensMessage + " - mint 1,000,000 tokens 0x0 -> ac3");
failIfTxStatusError(mintTokens2Tx, mintTokensMessage + " - mint 1,000,000 tokens 0x0 -> ac4");
printTxData("mintTokens1Tx", mintTokens1Tx);
printTxData("mintTokens2Tx", mintTokens2Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var startTransfersMessage = "Start Transfers";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + startTransfersMessage + " ---");
var startTransfers1Tx = token.disableMinting({from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var startTransfers2Tx = token.enableTransfers({from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(startTransfers1Tx, startTransfersMessage + " - Disable Minting");
failIfTxStatusError(startTransfers2Tx, startTransfersMessage + " - Enable Transfers");
printTxData("startTransfers1Tx", startTransfers1Tx);
printTxData("startTransfers2Tx", startTransfers2Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var unlockAccountsMessage = "Unlock Accounts";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + unlockAccountsMessage + " ---");
var unlockAccounts1Tx = token.unlockAccount(account3, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var unlockAccounts2Tx = token.unlockAccount(account4, {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(unlockAccounts1Tx, unlockAccountsMessage + " - unlock ac3");
failIfTxStatusError(unlockAccounts2Tx, unlockAccountsMessage + " - unlock ac4");
printTxData("unlockAccounts1Tx", unlockAccounts1Tx);
printTxData("unlockAccounts2Tx", unlockAccounts2Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var signedTransferMessage = "Signed Transfers";
var functionSig = web3.sha3("signedTransfer(address,address,uint256,uint256,uint256,bytes,address)").substring(0,10);
var tokenContractAddress = tokenAddress;
var from = account3;
var to = account5;
var tokens = new BigNumber("1000000000000000000");
var fee = new BigNumber("10000000000000000");
var feeToken = token;
var nonce = token.nextNonce(from);
// -----------------------------------------------------------------------------

var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(from) + addressToHex(to) + uint256ToHex(tokens) + uint256ToHex(fee) + uint256ToHex(nonce);
console.log("RESULT: hashOf=" + hashOf);
var hash = web3.sha3(hashOf, {encoding: 'hex'});
console.log("RESULT: hash=" + hash);

// -----------------------------------------------------------------------------
console.log("RESULT: --- " + signedTransferMessage + " ---");
console.log("RESULT: functionSig=" + functionSig + " (should be '0x7532eaac')");

console.log("RESULT: from=" + from);
console.log("RESULT: to=" + to);
console.log("RESULT: tokens=" + tokens + " " + tokens.shift(-decimals));
console.log("RESULT: fee=" + fee + " " + fee.shift(-decimals));
console.log("RESULT: nonce=" + nonce);
var signedTransferHash = token.signedTransferHash(from, to, tokens, fee, nonce);
console.log("RESULT: signedTransferHash=" + signedTransferHash);
console.log("RESULT: Should match hash=" + hash);
var sig = web3.eth.sign(from, signedTransferHash);
console.log("RESULT: sig=" + sig);

var signedTransfer1Check = token.signedTransferCheck(from, to, tokens, fee, nonce, sig, feeAccount);
console.log("RESULT: signedTransfer1Check=" + signedTransfer1Check + " " + signedTransferCheckResultString(signedTransfer1Check));
var signedTransfer1Tx = token.signedTransfer(from, to, tokens, fee, nonce, sig, feeAccount,
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(signedTransfer1Tx, signedTransferMessage + " - Signed Transfer ");
printTxData("signedTransfer1Tx", signedTransfer1Tx);
printTokenContractDetails();
console.log("RESULT: ");


var signedTransfer2Check = token.signedTransferCheck(from, to, tokens, fee, nonce, sig, feeAccount);
console.log("RESULT: signedTransfer2Check=" + signedTransfer2Check + " " + signedTransferCheckResultString(signedTransfer2Check));
var signedTransfer2Tx = token.signedTransfer(from, to, tokens, fee, nonce, sig, feeAccount,
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
passIfTxStatusError(signedTransfer2Tx, signedTransferMessage + " - Duplicated Signed Transfers - Expecting Failure");
printTxData("signedTransfer2Tx", signedTransfer2Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var signedApproveMessage = "Signed Approve";
var functionSig = web3.sha3("signedApprove(address,address,uint256,uint256,uint256,bytes,address)").substring(0,10);
var tokenContractAddress = tokenAddress;
var owner = account4;
var spender = account6;
var tokens = "50000000000000000000";
var fee = "500000000000000000";
var nonce = token.nextNonce(account4);
// -----------------------------------------------------------------------------

var signedApproveHash = token.signedApproveHash(owner, spender, tokens, fee, nonce);
console.log("RESULT: signedApproveHash=" + signedApproveHash);

// -----------------------------------------------------------------------------
console.log("RESULT: --- " + signedApproveMessage + " ---");
console.log("RESULT: functionSig=" + functionSig + " (should be '0xe9afa7a1')");

var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(owner) + addressToHex(spender) + uint256ToHex(tokens) + uint256ToHex(fee) + uint256ToHex(nonce);
console.log("RESULT: hashOf=" + hashOf);
var hash = web3.sha3(hashOf, {encoding: 'hex'});
console.log("RESULT: hash=" + hash);
console.log("RESULT: Should match signedApproveHash=" + signedApproveHash);
var sig = web3.eth.sign(account4, hash);

// var sig = web3.eth.sign(account4, signedApproveHash);
console.log("RESULT: sig=" + sig);
var r = getSigR(sig);
var s = getSigS(sig);
var v = getSigV(sig);
console.log("RESULT: sigR=" + r);
console.log("RESULT: sigS=" + s);
console.log("RESULT: sigV=" + v);

var signedApprove1Check = token.signedApproveCheck(owner, spender, tokens, fee, nonce, sig, feeAccount);
console.log("RESULT: signedApprove1Check=" + signedApprove1Check + " " + signedTransferCheckResultString(signedApprove1Check));
var signedApprove1Tx = token.signedApprove(owner, spender, tokens, fee, nonce, sig, feeAccount,
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var signedApprove2Check = token.signedApproveCheck(owner, spender, tokens, fee, nonce, sig, feeAccount);
console.log("RESULT: signedApprove2Check=" + signedApprove2Check + " " + signedTransferCheckResultString(signedApprove2Check));
var signedApprove2Tx = token.signedApprove(owner, spender, tokens, fee, nonce, sig, feeAccount,
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(signedApprove1Tx, signedApproveMessage + " - Signed Approve ");
passIfTxStatusError(signedApprove2Tx, signedApproveMessage + " - Duplicated Signed Approve - Expecting Failure");
printTxData("signedApprove1Tx", signedApprove1Tx);
printTxData("signedApprove2Tx", signedApprove2Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var signedTransferFromMessage = "Signed TransferFrom";
var functionSig = web3.sha3("signedTransferFrom(address,address,address,uint256,uint256,uint256,bytes,address)").substring(0,10);
var tokenContractAddress = tokenAddress;
var spender = account6;
var from = account4;
var to = account7;
var tokens = "3000000000000000000";
var fee = "30000000000000000";
var nonce = token.nextNonce(spender);

var signedTransferFromHash = token.signedTransferFromHash(spender, from, to, tokens, fee, nonce);
console.log("RESULT: signedTransferFromHash=" + signedTransferFromHash);

// -----------------------------------------------------------------------------
console.log("RESULT: --- " + signedTransferFromMessage + " ---");
console.log("RESULT: functionSig=" + functionSig + " (should be '0x344bcc7d')");

var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(spender) + addressToHex(from) + addressToHex(to) + uint256ToHex(tokens) + uint256ToHex(fee) + uint256ToHex(nonce);
console.log("RESULT: hashOf=" + hashOf);
var hash = web3.sha3(hashOf, {encoding: 'hex'});
console.log("RESULT: hash=" + hash);
console.log("RESULT: Should match signedTransferFromHash=" + signedTransferFromHash);
var sig = web3.eth.sign(account6, hash);

// var sig = web3.eth.sign(account4, signedTransferFromHash);
console.log("RESULT: sig=" + sig);
var r = getSigR(sig);
var s = getSigS(sig);
var v = getSigV(sig);
console.log("RESULT: sigR=" + r);
console.log("RESULT: sigS=" + s);
console.log("RESULT: sigV=" + v);

var signedTransferFrom1Check = token.signedTransferFromCheck(spender, from, to, tokens, fee, nonce, sig, feeAccount);
console.log("RESULT: signedTransferFrom1Check=" + signedTransferFrom1Check + " " + signedTransferCheckResultString(signedTransferFrom1Check));
var signedTransferFrom1Tx = token.signedTransferFrom(spender, from, to, tokens, fee, nonce, sig, feeAccount,
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var signedTransferFrom2Check = token.signedTransferFromCheck(spender, from, to, tokens, fee, nonce, sig, feeAccount);
console.log("RESULT: signedTransferFrom2Check=" + signedTransferFrom2Check + " " + signedTransferCheckResultString(signedTransferFrom2Check));
var signedTransferFrom2Tx = token.signedTransferFrom(spender, from, to, tokens, fee, nonce, sig, feeAccount,
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(signedTransferFrom1Tx, signedTransferMessage + " - Signed TransferFrom ");
passIfTxStatusError(signedTransferFrom2Tx, signedTransferMessage + " - Duplicated Signed TransfersFrom - Expecting Failure");
printTxData("signedTransferFrom1Tx", signedTransferFrom1Tx);
printTxData("signedTransferFrom2Tx", signedTransferFrom2Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var signedApproveAndCallMessage = "Test Signed ApproveAndCall 456.789 tokens with 'World' message";
var functionSig = web3.sha3("signedApproveAndCall(address,address,uint256,bytes,uint256,uint256,bytes,address)").substring(0,10);
var tokenContractAddress = tokenAddress;
var owner = account4;
var spender = testAddress;
var tokens = "456789000000000000000";
var data = "World";
var fee = "123000000000000000";
var nonce = token.nextNonce(owner);
// -----------------------------------------------------------------------------

var signedApproveAndCallHash = token.signedApproveAndCallHash(owner, spender, tokens, data, fee, nonce);
console.log("RESULT: signedApproveAndCallHash=" + signedApproveAndCallHash);

// -----------------------------------------------------------------------------
console.log("RESULT: --- " + signedApproveAndCallMessage + " ---");
console.log("RESULT: functionSig=" + functionSig + " (should be '0xf16f9b53')");

var hashOf = "0x" + bytes4ToHex(functionSig) + addressToHex(tokenContractAddress) + addressToHex(owner) + addressToHex(spender) + uint256ToHex(tokens) + stringToHex(data) + uint256ToHex(fee) + uint256ToHex(nonce);

console.log("RESULT: hashOf=" + hashOf);
var hash = web3.sha3(hashOf, {encoding: 'hex'});
console.log("RESULT: hash=" + hash);
console.log("RESULT: Should match signedApproveAndCallHash=" + signedApproveAndCallHash);
var sig = web3.eth.sign(account4, hash);

// var sig = web3.eth.sign(account4, signedApproveAndCallHash);
console.log("RESULT: sig=" + sig);

var signedApproveAndCall1Check = token.signedApproveAndCallCheck(owner, spender, tokens, data, fee, nonce, sig, feeAccount);
console.log("RESULT: signedApproveAndCall1Check=" + signedApproveAndCall1Check + " " + signedTransferCheckResultString(signedApproveAndCall1Check));
var signedApproveAndCall1Tx = token.signedApproveAndCall(owner, spender, tokens, data, fee, nonce, sig, feeAccount,
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var signedApproveAndCall2Check = token.signedApproveAndCallCheck(owner, spender, tokens, data, fee, nonce, sig, feeAccount);
console.log("RESULT: signedApproveAndCall2Check=" + signedApproveAndCall2Check + " " + signedTransferCheckResultString(signedApproveAndCall2Check));
var signedApproveAndCall2Tx = token.signedApproveAndCall(owner, spender, tokens, data, fee, nonce, sig, feeAccount,
  {from: contractOwnerAccount, gas: 200000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(signedApproveAndCall1Tx, signedApproveAndCallMessage);
passIfTxStatusError(signedApproveAndCall2Tx, signedApproveAndCallMessage + " - Duplicated - Expecting Failure");
printTxData("signedApproveAndCall1Tx", signedApproveAndCall1Tx);
printTxData("signedApproveAndCall2Tx", signedApproveAndCall2Tx);
printTokenContractDetails();
printTestContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var transferTokenMessage = "Transfer Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + transferTokenMessage + " ---");
var transferToken1Tx = token.transfer(account3, "100000000000000000000", {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
var transferToken2Tx = token.transfer(account4, "100000000000000000000", {from: contractOwnerAccount, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(transferToken1Tx, transferTokenMessage + " - transfer 100 tokens ac1 -> ac3");
failIfTxStatusError(transferToken2Tx, transferTokenMessage + " - transfer 100 tokens ac1 -> ac4");
printTxData("transferToken1Tx", transferToken1Tx);
printTxData("transferToken2Tx", transferToken2Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var approveAndCallTestMessage = "Test approveAndCall 123.456 tokens with 'Hello' message";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + approveAndCallTestMessage + " ---");
var approveAndCallTest1Tx = token.approveAndCall(testAddress,  "123456000000000000000", "Hello", {from: account3, gas: 400000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(approveAndCallTest1Tx, approveAndCallTestMessage);
printTxData("approveToken2Tx", approveAndCallTest1Tx);
printTokenContractDetails();
printTestContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move 0 Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + moveTokenMessage + " ---");
var moveToken1Tx = token.transfer(account5, "0", {from: account3, gas: 100000, gasPrice: defaultGasPrice});
var moveToken3Tx = token.transferFrom(account4, account7, "0", {from: account6, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(moveToken1Tx, moveTokenMessage + " - transfer 0 tokens ac3 -> ac5. SHOULD not throw");
failIfTxStatusError(moveToken3Tx, moveTokenMessage + " - transferFrom 0 tokens ac4 -> ac7 by ac6. SHOULD not throw");
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move More Tokens Than Owned";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + moveTokenMessage + " ---");
var moveToken1Tx = token.transfer(account5, "3000000000000000000000001", {from: account3, gas: 100000, gasPrice: defaultGasPrice});
var moveToken2Tx = token.approve(account6,  "3000000000000000000000001", {from: account4, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
var moveToken3Tx = token.transferFrom(account4, account7, "3000000000000000000000001", {from: account6, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
passIfTxStatusError(moveToken1Tx, moveTokenMessage + " - transfer 300K+1e-18 tokens ac3 -> ac5. SHOULD throw");
failIfTxStatusError(moveToken2Tx, moveTokenMessage + " - approve 300K+1e-18 tokens ac4 -> ac6");
passIfTxStatusError(moveToken3Tx, moveTokenMessage + " - transferFrom 300K+1e-18 tokens ac4 -> ac7 by ac6. SHOULD throw");
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken2Tx", moveToken2Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var approveTokenMessage = "Change Approval Without Setting To 0";
// -----------------------------------------------------------------------------
console.log("RESULT: --- " + approveTokenMessage + " ---");
var approveToken2Tx = token.approve(account6,  "3000000000000000000000002", {from: account4, gas: 100000, gasPrice: defaultGasPrice});
while (txpool.status.pending > 0) {
}
printBalances();
failIfTxStatusError(approveToken2Tx, approveTokenMessage + " - approve 300K+2e-18 tokens ac4 -> ac6");
printTxData("approveToken2Tx", approveToken2Tx);
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
