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

# geth attach << EOF
geth attach << EOF | grep ETHERDELTATRADE | sed "s/ETHERDELTATRADE: //" > gzeEtherDeltaTrades.txt

loadScript("bttsToken.js");
loadScript("etherDelta.js");
loadScript("idex.js");

var token = web3.eth.contract(bttsTokenAbi).at(gzeAddress);
var etherDelta = web3.eth.contract(etherDeltaAbi).at(etherDeltaAddress);
var idex = web3.eth.contract(idexAbi).at(idexAddress);
// After old GZE snapshot
var fromBlock = 5068576;
// TEST var fromBlock = 4040064;
var toBlock = eth.blockNumber;
// var toBlock = parseInt(fromBlock) + 100000;
var block = eth.getBlock(toBlock);
console.log("Snapshot at block=" + block.number + " time=" + block.timestamp + " " + new Date(block.timestamp * 1000).toUTCString());

function getExchangeTradesAccounts() {
  var accounts = {};
  var etherDeltaTradeEvents = etherDelta.Trade({}, {fromBlock: fromBlock, toBlock: toBlock});
  etherDeltaTradeEvents.watch(function (error, result) {
    if (result.args.tokenGet == gzeAddress || result.args.tokenGive == gzeAddress) {
      // console.log("ETHERDELTATRADE: " + JSON.stringify(result));
      console.log("ETHERDELTATRADE: " + result.args.get + "\tget\t" + result.args.give + 
        "\tgive\t" + result.args.amountGet.shift(-18) + "\tgetAmt\t" + result.args.tokenGet + 
        "\ttokenGet\t" + result.args.amountGive.shift(-18) + "\tgiveAmt\t" + result.args.tokenGive + 
        "\ttokenGive\t" + result.transactionHash);

      // ETHERDELTATRADE: {"address":"0x8d12a197cb00d4747a1fe03395095ce2a5cc6819",
      // "args":{"amountGet":"1.775537832718572425481e+21","amountGive":"390618323198085933",
      // "get":"0x97a7eaf6de79381d90400af96ed5be34b5f77c41","give":"0x6bce2148d03e4ce04bc802c423756a72851a44b4",
      // "tokenGet":"0x8c65e992297d5f092a756def24f4781a280198ff","tokenGive":"0x0000000000000000000000000000000000000000"},
      // "blockHash":"0x16c69b78bbf9b2f6fe6e29008b7dc96686cd6f96453503aed9b2bab189a47aa2","blockNumber":5069223,
      // "event":"Trade","logIndex":4,"removed":false,"transactionHash":"0x8aa8244963bbbf752b1968a4d5073dde20bbc14c12392083856766951043b061",
      // "transactionIndex":9}
      accounts[result.args.get] = 1;
      accounts[result.args.give] = 1;
    }
  });
  etherDeltaTradeEvents.stopWatching();
  return Object.keys(accounts).sort();
}

var accounts = getExchangeTradesAccounts();
// console.log("DATA: var exchangeTradesAccounts$END=" + JSON.stringify(accounts) + ";");

EOF

# grep "DATA: " exchangeTradesAccounts.txt | sed "s/DATA: //" > exchangeTradesAccounts$END.js
