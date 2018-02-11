#!/bin/sh
# ----------------------------------------------------------------------------------------------
# Extract Token Balances
#
# Based on https://github.com/BitySA/whetcwithdraw/tree/master/daobalance
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
# ----------------------------------------------------------------------------------------------

# geth attach rpc:http://192.168.4.120:8545 << EOF
# geth attach rpc:http://localhost:8545 << EOF > oldTokenBalances.txt
geth attach << EOF > reconcile.txt

var sendingAddress="0xe796ad819e32846a7f2b28288a23f682eb4da9b4";

loadScript("bttsToken.js");
loadScript("etherDelta.js");
loadScript("newToken.js");
loadScript("exchangeTradesAccounts4900000.js");
loadScript("exchangeTradesAccounts4920000.js");
loadScript("exchangeTradesAccounts4940000.js");
loadScript("exchangeTradesAccounts4960000.js");
loadScript("exchangeTradesAccounts4980000.js");
loadScript("exchangeTradesAccounts5000000.js");
loadScript("exchangeTradesAccounts5020000.js");
loadScript("exchangeTradesAccounts5040000.js");
// loadScript("exchangeTradesAccounts5059831.js");
loadScript("exchangeTradesAccounts5068224.js");


var exchangeTradesAccounts=exchangeTradesAccounts4900000.concat(exchangeTradesAccounts4920000).concat(exchangeTradesAccounts4940000)\
    .concat(exchangeTradesAccounts4960000).concat(exchangeTradesAccounts4980000).concat(exchangeTradesAccounts5000000)\
    .concat(exchangeTradesAccounts5020000).concat(exchangeTradesAccounts5040000).concat(exchangeTradesAccounts5068224)\
    .concat([etherDeltaFeeAccount]);
// console.log("exchangeTradesAccounts=" + JSON.stringify(exchangeTradesAccounts));

var D160 = new BigNumber("10000000000000000000000000000000000000000", 16);
var token = web3.eth.contract(bttsTokenAbi).at(gzeAddress);
var newToken = web3.eth.contract(tokenAbi).at(tokenAddress);
var etherDelta = web3.eth.contract(etherDeltaAbi).at(etherDeltaAddress);
var etherDeltaAddressLower = etherDeltaAddress.toLowerCase();
var fromBlock = gzeFromBlock;
// TEST var fromBlock = 4040064;
var toBlock = 5068576;
var newTokenToBlock = eth.blockNumber;
// var toBlock = parseInt(fromBlock) + 1000;
var atBlock = toBlock;
// var atBlock = 5002000;
var block = eth.getBlock(toBlock);
console.log("Snapshot at block=" + block.number + " time=" + block.timestamp + " " + new Date(block.timestamp * 1000).toUTCString());

function getAccounts() {
  var accounts = {};
  var transferEventsFilter = token.Transfer({}, {fromBlock: fromBlock, toBlock: toBlock});
  var transferEvents = transferEventsFilter.get();
  for (var i = 0; i < transferEvents.length; i++) {
    var transferEvent = transferEvents[i];
    // console.log(JSON.stringify(transferEvent));
    accounts[transferEvent.args.from] = 1;
    accounts[transferEvent.args.to] = 1;
  }
  for (var i = 0; i < exchangeTradesAccounts.length; i++) {
    accounts[exchangeTradesAccounts[i]] = 1;
  }
  return Object.keys(accounts).sort();
}

function getBalancesAndCompress(accounts) {
    var totalSupply = token.totalSupply(atBlock);
    console.log("BALANCE: #\tAccount\tAmount\tSumAmountExclExch\tAmountDecimals\tSumAmountDecimalsExclExch\tEtherDeltaAmount\tSumEtherDeltaAmount\tEtherDeltaAmountDecimals\tSumEtherDeltaAmountDecimals\tDiff\tDiffDecimals\tNewAccountBalance\tNewAccountBalanceDecimals\tNewTokenBalance\tNewTokenBalanceDecimals\tIsContract\tBlock");
    var balances = [];
    var totalBalance = new BigNumber(0);
    var etherDeltaBalance = new BigNumber(0);
    for (var i = 0; i < accounts.length; i++) {
        var account = accounts[i];
        var amount = token.balanceOf(account, atBlock);
        var addressNum = new BigNumber(account.substring(2), 16);
        var v = D160.mul(amount).add(addressNum);
        var etherDeltaAmount = etherDelta.tokens(gzeAddress, account, atBlock);
        if (amount.greaterThan(0) || etherDeltaAmount.greaterThan(0)) {
            balances.push(v.toString(10));
            var newAccountBalance = new BigNumber(0);
            if (account != etherDeltaAddressLower) {
                totalBalance = totalBalance.add(amount);
                newAccountBalance = amount.add(etherDeltaAmount);
            }
            etherDeltaBalance = etherDeltaBalance.add(etherDeltaAmount);
            var isContract = eth.getCode(account) != "0x" ? "y" : "n";
            var diff = totalSupply.sub(totalBalance).sub(etherDeltaBalance);
            // if (i%100 === 0) console.log("Processed: " + i);
            var newTokenBalance = new BigNumber(0);
            if (account != etherDeltaAddressLower) {
                newTokenBalance = newToken.balanceOf(account);
            }
            console.log("BALANCE: " + i + "\t" + account + "\t" + amount.toFixed(0) + "\t" + totalBalance.toFixed(0) + "\t" +
                amount.shift(-18) + "\t" + totalBalance.shift(-18) + "\t" +
                etherDeltaAmount.toFixed(0) + "\t" + etherDeltaBalance.toFixed(0) + "\t" + etherDeltaAmount.shift(-18) + "\t" + etherDeltaBalance.shift(-18) + "\t" +
                diff.shift(-18) + "\t" + diff.toFixed(0) + "\t" +
                newAccountBalance.toFixed(0) + "\t" + newAccountBalance.shift(-18) + "\t" +
                newTokenBalance.toFixed(0) + "\t" + newTokenBalance.shift(-18) + "\t" +
                isContract + "\t" + block.number);
        }
    }
    console.log("Total balance=" + totalBalance.toString(10));
    console.log("totalSupply=" + token.totalSupply().toString(10));
    return balances;
}

var accounts = getAccounts();
console.log(JSON.stringify(accounts));
console.log("number of accounts, some may have a zero balances=" + accounts.length);

var balances = getBalancesAndCompress(accounts);
console.log("number of accounts+balances, only with non-zero balances=" + balances.length);
// console.log(JSON.stringify(balances, null, 2));
// console.log(JSON.stringify(balances));

EOF

grep "BALANCE: " reconcile.txt | sed "s/BALANCE: //" > reconcile.tsv
# grep "DATA: " oldTokenBalances.txt | sed "s/DATA: //" > oldTokenBalancesData.js
