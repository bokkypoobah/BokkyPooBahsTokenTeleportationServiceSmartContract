#!/bin/sh
# ----------------------------------------------------------------------------------------------
# Extract Token Balances
#
# Based on https://github.com/BitySA/whetcwithdraw/tree/master/daobalance
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018. The MIT Licence.
# ----------------------------------------------------------------------------------------------

# var firstGzeTransfer=4806786;
# var firstEveTransfer=4964407;

# START=4806786
# END=4850000
# START=4850001
# END=4875000
# START=4875001
# END=4880000
# START=4880001
# END=4900000
# START=4900001
# END=4920000
# START=4920001
# END=4940000
# START=4940001
# END=4960000
# START=4960001
# END=4980000
# START=4980001
# END=5000000
# START=5000001
# END=5020000
# START=5020001
# END=5040000
START=5040001
END=5068224

geth attach << EOF > exchangeTradesAccounts.txt

loadScript("bttsToken.js");
loadScript("etherDelta.js");
loadScript("idex.js");

var token = web3.eth.contract(bttsTokenAbi).at(gzeAddress);
var etherDelta = web3.eth.contract(etherDeltaAbi).at(etherDeltaAddress);
var idex = web3.eth.contract(idexAbi).at(idexAddress);
var fromBlock = $START;
// TEST var fromBlock = 4040064;
// var toBlock = eth.blockNumber;
var toBlock = $END;
// var toBlock = parseInt(fromBlock) + 100000;
var block = eth.getBlock(toBlock);
console.log("Snapshot at block=" + block.number + " time=" + block.timestamp + " " + new Date(block.timestamp * 1000).toUTCString());

function getExchangeTradesAccounts() {
  var accounts = {};
  var etherDeltaTradeEvents = etherDelta.Trade({}, {fromBlock: fromBlock, toBlock: toBlock});
  etherDeltaTradeEvents.watch(function (error, result) {
    if (result.args.tokenGet == gzeAddress || result.args.tokenGive == gzeAddress || result.args.tokenGet == eveAddress || result.args.tokenGive == eveAddress) {
      console.log("ETHERDELTATRADE: " + JSON.stringify(result));
      accounts[result.args.get] = 1;
      accounts[result.args.give] = 1;
    }
  });
  etherDeltaTradeEvents.stopWatching();
  var idexTradeEvents = idex.Trade({}, {fromBlock: fromBlock, toBlock: toBlock});
  idexTradeEvents.watch(function (error, result) {
    if (result.args.tokenGet == gzeAddress || result.args.tokenGive == gzeAddress || result.args.tokenGet == eveAddress || result.args.tokenGive == eveAddress) {
      console.log("IDEXTRADE: " + JSON.stringify(result));
      accounts[result.args.get] = 1;
      accounts[result.args.give] = 1;
    }
  });
  idexTradeEvents.stopWatching();
  return Object.keys(accounts).sort();
}

var accounts = getExchangeTradesAccounts();
console.log("DATA: var exchangeTradesAccounts$END=" + JSON.stringify(accounts) + ";");

EOF

grep "DATA: " exchangeTradesAccounts.txt | sed "s/DATA: //" > exchangeTradesAccounts$END.js
