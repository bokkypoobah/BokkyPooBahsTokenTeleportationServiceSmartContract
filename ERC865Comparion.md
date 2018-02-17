## Comparison Of The Proposed ERC865 To BTTS

The ERC865 standard is still evolving, but the comparison below is based on the PROPSProject implementation as of Feb 17 2018.

ERC865 information: https://github.com/ethereum/EIPs/issues/865

An implementation of ERC865: 

* https://github.com/PROPSProject/props-token-distribution/blob/aa52ef6ad134e6b3939c9f4208bb53d8a00221b0/contracts/token/ERC865.sol

* https://github.com/PROPSProject/props-token-distribution/blob/aa52ef6ad134e6b3939c9f4208bb53d8a00221b0/contracts/token/ERC865Token.sol

## Additional Events

The following 2 events are logged in the ERC865 implementation:

```javascript
    event TransferPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
    event ApprovalPreSigned(address indexed from, address indexed to, address indexed delegate, uint256 amount, uint256 fee);
```

<br />

## transfer

ERC865 has the following signature:

```javascript
function transferPreSigned(
    bytes _signature,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce
) public returns (bool);
```

BTTS v1.10 has the following signature:

```javascript
function signedTransfer(
    address tokenOwner, 
    address to, 
    uint tokens, 
    uint fee, 
    uint nonce, 
    bytes sig, 
    address feeAccount
) public returns (bool success);
```

<br />

## approve

ERC865 has the following signature:

```javascript
function approvePreSigned(
    bytes _signature,
    address _spender,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce
) public returns (bool);
```

BTTS v1.10 has the following signature:

```javascript
function signedApprove(
    address tokenOwner, 
    address spender, 
    uint tokens, 
    uint fee, 
    uint nonce, 
    bytes sig, 
    address feeAccount
) public returns (bool success);
```

ERC865 also has the following functions:

```javascript
function increaseApprovalPreSigned(
    bytes _signature,
    address _spender,
    uint256 _addedValue,
    uint256 _fee,
    uint256 _nonce
) public returns (bool);
```

and

```javascript
function decreaseApprovalPreSigned(
    bytes _signature,
    address _spender,
    uint256 _subtractedValue,
    uint256 _fee,
    uint256 _nonce
) public returns (bool);
```

<br />

## transferFrom

ERC865 has the following signature:

```javascript
function transferFromPreSigned(
    bytes _signature,
    address _from,
    address _to,
    uint256 _value,
    uint256 _fee,
    uint256 _nonce
) public returns (bool);
```

BTTS v1.10 has the following signature:

```javascript
function signedTransferFrom(
    address spender, 
    address from, 
    address to, 
    uint tokens, 
    uint fee, 
    uint nonce, 
    bytes sig, 
    address feeAccount
) public returns (bool success);
```