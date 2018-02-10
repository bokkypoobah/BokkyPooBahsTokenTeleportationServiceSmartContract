// -----------------------------------------------------------------------------
// BTTS support functions
// -----------------------------------------------------------------------------
function signedTransferCheckResultString(e) {
  var text = "Unknown";
  if (e == 0) {
    text = "Success"
  } else if (e == 1) {
    text = "NotTransferable";
  } else if (e == 2) {
    text = "AccountLocked";
  } else if (e == 3) {
    text = "SignerMismatch";
  } else if (e == 4) {
    text = "InvalidNonce";
  } else if (e == 5) {
    text = "InsufficientApprovedTokens";
  } else if (e == 6) {
    text = "InsufficientApprovedTokensForFees";
  } else if (e == 7) {
    text = "InsufficientTokens";
  } else if (e == 8) {
    text = "InsufficientTokensForFees";
  } else if (e == 9) {
    text = "OverflowError";
  } else {
    text = "Unknown";
  }
  return text;
}

function padLeft0(s, n) {
  var result = s.toString();
  while (result.length < n) {
    result = "0" + result;
  }
  return result;
}

function bytes4ToHex(bytes4) {
  if (bytes4.substring(0, 2) == "0x") {
    return padLeft0(bytes4.substring(2, 10), 8);
  } else {
    return padLeft0(bytes4.substring(0, 8), 8);
  } 
}

function addressToHex(address) {
  if (address.substring(0, 2) == "0x") {
    return padLeft0(address.substring(2, 42).toLowerCase(), 40);
  } else {
    return padLeft0(address.substring(0, 40).toLowerCase(), 40);
  } 
}

function uint256ToHex(number) {
  var bigNumber = new BigNumber(number).toString(16);
  if (bigNumber.substring(0, 2) == "0x") {
    return padLeft0(bigNumber.substring(2, 66).toLowerCase(), 64);
  } else {
    return padLeft0(bigNumber.substring(0, 64).toLowerCase(), 64);
  } 
}

function stringToHex(s) {
  return web3.toHex(s).substring(2);
}

function getSigR(sig) {
  if (sig.substring(0, 2) == "0x") {
    return "0x" + sig.substring(2, 66);
  } else {
    return "0x" + sig.substring(0, 64)
  } 
}

function getSigS(sig) {
  if (sig.substring(0, 2) == "0x") {
    return "0x" + sig.substring(66, 130);
  } else {
    return "0x" + sig.substring(64, 128)
  } 
}

function getSigV(sig) {
  if (sig.substring(0, 2) == "0x") {
    return "0x" + sig.substring(130, 132);
  } else {
    return "0x" + sig.substring(128, 130)
  } 
}
