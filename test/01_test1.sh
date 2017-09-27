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

CROWDSALESOL=`grep ^CROWDSALESOL= settings.txt | sed "s/^.*=//"`
CROWDSALEJS=`grep ^CROWDSALEJS= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

BLOCKSINDAY=10

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
printf "CROWDSALESOL    = '$CROWDSALESOL'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALEJS     = '$CROWDSALEJS'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA  = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS       = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT     = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS    = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME     = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "STARTTIME       = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST1OUTPUT
printf "ENDTIME         = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
# `cp modifiedContracts/SnipCoin.sol .`
`cp $SOURCEDIR/$CROWDSALESOL .`

# --- Modify parameters ---
# `perl -pi -e "s/bool transferable/bool public transferable/" $TOKENSOL`
# `perl -pi -e "s/MULTISIG_WALLET_ADDRESS \= 0xc79ab28c5c03f1e7fbef056167364e6782f9ff4f;/MULTISIG_WALLET_ADDRESS \= 0xa22AB8A9D641CE77e06D98b7D7065d324D3d6976;/" GimliCrowdsale.sol`
# `perl -pi -e "s/START_DATE = 1505736000;.*$/START_DATE \= $STARTTIME; \/\/ $STARTTIME_S/" GimliCrowdsale.sol`
# `perl -pi -e "s/END_DATE = 1508500800;.*$/END_DATE \= $ENDTIME; \/\/ $ENDTIME_S/" GimliCrowdsale.sol`
# `perl -pi -e "s/VESTING_1_DATE = 1537272000;.*$/VESTING_1_DATE \= $VESTING1TIME; \/\/ $VESTING1TIME_S/" GimliCrowdsale.sol`
# `perl -pi -e "s/VESTING_2_DATE = 1568808000;.*$/VESTING_2_DATE \= $VESTING2TIME; \/\/ $VESTING2TIME_S/" GimliCrowdsale.sol`

DIFFS1=`diff $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL`
echo "--- Differences $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

echo "var tokenOutput=`solc --optimize --combined-json abi,bin,interface $CROWDSALESOL`;" > $CROWDSALEJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$CROWDSALEJS");
loadScript("functions.js");

var libAbi = JSON.parse(tokenOutput.contracts["$CROWDSALESOL:SafeMath"].abi);
var libBin = "0x" + tokenOutput.contracts["$CROWDSALESOL:SafeMath"].bin;
var tokenAbi = JSON.parse(tokenOutput.contracts["$CROWDSALESOL:BATTToken"].abi);
var tokenBin = "0x" + tokenOutput.contracts["$CROWDSALESOL:BATTToken"].bin;

// console.log("DATA: libAbi=" + JSON.stringify(libAbi));
// console.log("DATA: libBin=" + JSON.stringify(libBin));
// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var deployLibraryMessage = "Deploy Crowdsale/Token Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + deployLibraryMessage);
var libContract = web3.eth.contract(libAbi);
// console.log(JSON.stringify(tokenContract));
var libTx = null;
var libAddress = null;

var lib = libContract.new({from: contractOwnerAccount, data: libBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        libTx = contract.transactionHash;
      } else {
        libAddress = contract.address;
        addAccount(libAddress, "Lib SafeMath");
        console.log("DATA: libAddress=" + libAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("libAddress=" + libAddress, libTx);
printBalances();
failIfGasEqualsGasUsed(libTx, deployLibraryMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var tokenMessage = "Deploy Crowdsale/Token Contract";
console.log("RESULT: old='" + tokenBin + "'");
var newTokenBin = tokenBin.replace(/__BATTToken\.sol\:SafeMath________________/g, libAddress.substring(2, 42));
console.log("RESULT: new='" + newTokenBin + "'");
// -----------------------------------------------------------------------------
console.log("RESULT: " + tokenMessage);
var tokenContract = web3.eth.contract(tokenAbi);
// console.log(JSON.stringify(tokenContract));
var tokenTx = null;
var tokenAddress = null;

var token = tokenContract.new({from: contractOwnerAccount, data: newTokenBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        tokenTx = contract.transactionHash;
      } else {
        tokenAddress = contract.address;
        addAccount(tokenAddress, "Token '" + token.symbol() + "' '" + token.name() + "'");
        addTokenContractAddressAndAbi(tokenAddress, tokenAbi);
        console.log("DATA: tokenAddress=" + tokenAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("tokenAddress=" + tokenAddress, tokenTx);
printBalances();
failIfGasEqualsGasUsed(tokenTx, tokenMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var transferTokenMessage = "Transfer Tokens";
// -----------------------------------------------------------------------------
console.log("RESULT: " + transferTokenMessage);
var transferToken1Tx = token.transfer(account3, "100000000000000000000", {from: contractOwnerAccount, gas: 100000});
var transferToken2Tx = token.transfer(account4, "100000000000000000000", {from: contractOwnerAccount, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("transferToken1Tx", transferToken1Tx);
printTxData("transferToken2Tx", transferToken2Tx);
printBalances();
failIfGasEqualsGasUsed(transferToken1Tx, transferTokenMessage + " - transfer 10,000 tokens ac1 -> ac3");
failIfGasEqualsGasUsed(transferToken2Tx, transferTokenMessage + " - transfer 10,000 tokens ac1 -> ac4");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move 0 Tokens After Transfers Allowed";
// -----------------------------------------------------------------------------
console.log("RESULT: " + moveTokenMessage);
var moveToken1Tx = token.transfer(account5, "0", {from: account3, gas: 100000});
var moveToken3Tx = token.transferFrom(account4, account7, "0", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printBalances();
failIfGasEqualsGasUsed(moveToken1Tx, moveTokenMessage + " - transfer 0 tokens ac3 -> ac5. SHOULD not throw");
failIfGasEqualsGasUsed(moveToken3Tx, moveTokenMessage + " - transferFrom 0 tokens ac4 -> ac7 by ac6. SHOULD not throw");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move More Tokens Than Owned";
// -----------------------------------------------------------------------------
console.log("RESULT: " + moveTokenMessage);
var moveToken1Tx = token.transfer(account5, "3000000000000000000000001", {from: account3, gas: 100000});
var moveToken2Tx = token.approve(account6,  "3000000000000000000000001", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
var moveToken3Tx = token.transferFrom(account4, account7, "3000000000000000000000001", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken2Tx", moveToken2Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printBalances();
passIfGasEqualsGasUsed(moveToken1Tx, moveTokenMessage + " - transfer 300K+1e-18 tokens ac3 -> ac5. SHOULD throw");
failIfGasEqualsGasUsed(moveToken2Tx, moveTokenMessage + " - approve 300K+1e-18 tokens ac4 -> ac6");
passIfGasEqualsGasUsed(moveToken3Tx, moveTokenMessage + " - transferFrom 300K+1e-18 tokens ac4 -> ac7 by ac6. SHOULD throw");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var approveTokenMessage = "Change Approval Without Setting To 0";
// -----------------------------------------------------------------------------
console.log("RESULT: " + approveTokenMessage);
var approveToken2Tx = token.approve(account6,  "3000000000000000000000002", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("approveToken2Tx", approveToken2Tx);
printBalances();
passIfGasEqualsGasUsed(approveToken2Tx, approveTokenMessage + " - approve 300K+2e-18 tokens ac4 -> ac6. SHOULD throw");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var approveTokenMessage = "Change Approval By Setting To 0 In Between";
// -----------------------------------------------------------------------------
console.log("RESULT: " + approveTokenMessage);
var approveToken2Tx = token.approve(account6,  "0", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
var approveToken3Tx = token.approve(account6,  "3000000000000000000000002", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("approveToken2Tx", approveToken2Tx);
printTxData("approveToken3Tx", approveToken3Tx);
printBalances();
failIfGasEqualsGasUsed(approveToken2Tx, approveTokenMessage + " - approve 0 tokens ac4 -> ac6");
failIfGasEqualsGasUsed(approveToken3Tx, approveTokenMessage + " - approve 300K+2e-18 tokens ac4 -> ac6");
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
