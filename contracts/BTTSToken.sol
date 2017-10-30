pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
// BTTS 'BokkyPooBah's Token Teleportation Service' token interface and
// sample implementation
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    uint public totalSupply;
    function balanceOf(address owner) public constant returns (uint balance);
    function transfer(address to, uint amount) public returns (bool success);
    function transferFrom(address from, address to, uint tokens)
        public returns (bool success);
    function approve(address spender, uint tokens)
        public returns (bool success);
    function allowance(address owner, address spender)
        public constant returns (uint remaining);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed owner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service (BTTS) Base v1.00
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSBase {

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
        NotExecutable,                     // 2 Tokens not transferable yet
        SignerMismatch,                    // 3 Mismatch in signing account
        AlreadyExecuted,                   // 4 Transfer already executed
        InsufficientApprovedTokens,        // 5 Insufficient approved tokens
        InsufficientApprovedTokensForFees, // 6 Insufficient approved tokens for fees
        InsufficientTokens,                // 7 Insufficient tokens
        InsufficientTokensForFees,         // 8 Insufficient tokens for fees
        OverflowError                      // 9 Overflow error
    }

    /*
    // Duplicate Solidity's ecrecover, but catching the CALL return value
    function safer_ecrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal view returns (bool, address) {
        // We do our own memory management here. Solidity uses memory offset
        // 0x40 to store the current end of memory. We write past it (as
        // writes are memory extensions), but don't update the offset so
        // Solidity will reuse it. The memory used here is only needed for
        // this context.

        // FIXME: inline assembly can't access return values
        bool ret;
        address addr;

        assembly {
            let size := mload(0x40)
            mstore(size, hash)
            mstore(add(size, 32), v)
            mstore(add(size, 64), r)
            mstore(add(size, 96), s)

            // NOTE: we can reuse the request memory because we deal with
            //       the return code
            ret := call(3000, 1, 0, size, 128, size, 32)
            addr := mload(size)
        }

        return (ret, addr);
    }*/

    // Borrowed from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    //
    function ecrecovery(bytes32 hash, bytes sig) public pure returns (bool, address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return (false, 0);

        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))

            // Here we are loading the last 32 bytes. We exploit the fact that
            // 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))

            // Alternative solution:
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            // v := and(mload(add(sig, 65)), 255)
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return (false, 0);

        // return safer_ecrecover(hash, v, r, s);
        return (true, ecrecover(hash, v, r, s));
    }

    function ecverify(bytes32 hash, bytes sig, address signer) public pure returns (bool) {
        bool ret;
        address addr;
        (ret, addr) = ecrecovery(hash, sig);
        return ret == true && addr == signer;
    }

    function ecrecoverFromSig(bytes32 hash, bytes sig) public pure returns (address addr) {
        bool ret;
        (ret, addr) = ecrecovery(hash, sig);
    }
}

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
contract BTTSInterface is BTTSBase {

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
        uint fee, uint nonce, bytes sig)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute a transfer on behalf of the user who signed the transfer 
    // message
    // ------------------------------------------------------------------------
    function signedTransfer(address owner, address to, uint tokens, uint fee,
        uint nonce, bytes sig)
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
        uint fee, uint nonce, bytes sig)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute an approve on behalf of the user who signed the approve message
    // ------------------------------------------------------------------------
    function signedApprove(address owner, address spender, uint tokens,
        uint fee, uint nonce, bytes sig)
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
        uint tokens, uint fee, uint nonce, bytes sig)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute a transferFrom on behalf of the user who signed the transferFrom 
    // message
    // ------------------------------------------------------------------------
    function signedTransferFrom(address spender, address from, address to,
        uint tokens, uint fee, uint nonce, bytes sig)
        public returns (bool success);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {

    // ------------------------------------------------------------------------
    // Current owner, and proposed new owner
    // ------------------------------------------------------------------------
    address public owner;
    address public newOwner;

    // ------------------------------------------------------------------------
    // Constructor - assign creator as the owner
    // ------------------------------------------------------------------------
    function Owned() public {
        owner = msg.sender;
    }

    // ------------------------------------------------------------------------
    // Modifier to mark that a function can only be executed by the owner
    // ------------------------------------------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    // ------------------------------------------------------------------------
    // Owner can initiate transfer of contract to a new owner
    // ------------------------------------------------------------------------
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    // ------------------------------------------------------------------------
    // New owner has to accept transfer of contract
    // ------------------------------------------------------------------------
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }

    // ------------------------------------------------------------------------
    // Owner can initiate transfer of contract to a new owner
    // ------------------------------------------------------------------------
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
        newOwner = 0x0;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
}


/*
// ----------------------------------------------------------------------------
// Administrators
// ----------------------------------------------------------------------------
contract Admin is Owned {

    // ------------------------------------------------------------------------
    // Mapping of administrators
    // ------------------------------------------------------------------------
    mapping (address => bool) public admins;

    // ------------------------------------------------------------------------
    // Add and delete admin events
    // ------------------------------------------------------------------------
    event AdminAdded(address _address);
    event AdminRemoved(address _address);

    // ------------------------------------------------------------------------
    // Modifier for functions that can only be executed by adminstrator
    // ------------------------------------------------------------------------
    modifier onlyAdmin() {
        require(admins[msg.sender] || owner == msg.sender);
        _;
    }

    // ------------------------------------------------------------------------
    // Owner can add a new administrator
    // ------------------------------------------------------------------------
    function addAdmin(address _address) public onlyOwner {
        admins[_address] = true;
        AdminAdded(_address);
    }

    // ------------------------------------------------------------------------
    // Owner can remove an administrator
    // ------------------------------------------------------------------------
    function removeAdmin(address _address) public onlyOwner {
        delete admins[_address];
        AdminRemoved(_address);
    }
}
*/

// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) public pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    function sub(uint a, uint b) public pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    // ------------------------------------------------------------------------
    // Multiply two numbers
    // ------------------------------------------------------------------------
    function mul(uint a, uint b) public pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Multiply one number by another number
    // ------------------------------------------------------------------------
    function div(uint a, uint b) public pure returns (uint) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract ERC20Token is ERC20Interface, Owned {
    using SafeMath for uint;

    // ------------------------------------------------------------------------
    // Token parameters
    // ------------------------------------------------------------------------
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public decimalsFactor;
    uint public totalSupply;

    // ------------------------------------------------------------------------
    // Token contract state
    // ------------------------------------------------------------------------
    bool public mintable;
    bool public transferable;

    // ------------------------------------------------------------------------
    // Balances for each account
    // ------------------------------------------------------------------------
    mapping(address => uint) balances;

    // ------------------------------------------------------------------------
    // Owner of account approves the transfer of an amount to another account
    // ------------------------------------------------------------------------
    mapping(address => mapping(address => uint)) allowed;

    // ------------------------------------------------------------------------
    // Executed signed transfers
    // ------------------------------------------------------------------------
    mapping(address => mapping(bytes32 => bool)) public executed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function ERC20Token(string _symbol, string _name, uint8 _decimals, 
        uint _initialSupply, bool _mintable, bool _transferable) public 
    {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        decimalsFactor = 10**uint(_decimals);
        if (_initialSupply > 0) {
            balances[owner] = _initialSupply;
            totalSupply = _initialSupply;
            Transfer(0x0, owner, _initialSupply);
        }
        mintable = _mintable;
        transferable = _transferable;
    }

    event MintingDisabled();
    event TransfersEnabled();

    // ------------------------------------------------------------------------
    // Can transfer functions be executed?
    // ------------------------------------------------------------------------
    modifier canTransfer() {
        require(transferable);
        _;
    }

    // ------------------------------------------------------------------------
    // Disable minting
    // ------------------------------------------------------------------------
    function disableMinting() public onlyOwner {
        require(mintable);
        mintable = false;
        MintingDisabled();
    }


    // ------------------------------------------------------------------------
    // Enable transfers
    // ------------------------------------------------------------------------
    function enableTransfers() public onlyOwner {
        require(!transferable);
        transferable = true;
        TransfersEnabled();
    }


    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    function balanceOf(address owner) public constant returns (uint balance) {
        return balances[owner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public canTransfer returns (bool success) {
        require(balances[msg.sender] >= tokens);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Approve `spender` to withdraw `tokens` tokens from the owner's account
    //
    // As recommended in https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#approve
    // there are no checks for the approval double-spend attack as this should
    // be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens)
        public returns (bool success) 
    {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // 
    
    // Spender of tokens transfer an amount of tokens from the token owner's
    // balance to another account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens)
        public canTransfer returns (bool success)
    {
        require(balances[from] >= tokens);
        require(allowed[from][msg.sender] >= tokens);

        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address owner, address spender)
        public constant returns (uint remaining)
    {
        return allowed[owner][spender];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from owner's account to another account
    // - Account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function mint(address to, uint tokens)
        public onlyOwner returns (bool success)
    {
        require(mintable);
        balances[to] = balances[to].add(tokens);
        totalSupply = totalSupply.add(tokens);
        Transfer(0x0, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ethers - no payable modifier
    // ------------------------------------------------------------------------
    function () public {
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens)
      public onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}


// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service (BTTS) Token Implementation v1.00
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
        uint fee, uint nonce, bytes sig)
        public constant returns (CheckResult result)
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check owner is the message signer
        bytes32 hash = signedTransferHash(owner, to, tokens, fee, nonce);
        if (owner != ecrecoverFromSig(keccak256(signingPrefix, hash), sig))
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
        uint nonce, bytes sig)
        public canTransfer returns (bool success)
    {
        // Check owner is the message signer
        bytes32 hash = signedTransferHash(owner, to, tokens, fee, nonce);
        require(owner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

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
        uint fee, uint nonce, bytes sig)
        public constant returns (CheckResult result) 
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check owner is the message signer
        bytes32 hash = signedApproveHash(owner, spender, tokens, fee, nonce);
        if (owner != ecrecoverFromSig(keccak256(signingPrefix, hash), sig))
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
        uint fee, uint nonce, bytes sig)
        public canTransfer returns (bool success) 
    {
        // Check owner is the message signer
        bytes32 hash = signedApproveHash(owner, spender, tokens, fee, nonce);
        require(owner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

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
        uint tokens, uint fee, uint nonce, bytes sig)
        public constant returns (CheckResult result)
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check spender is the message signer
        bytes32 hash = signedTransferFromHash(spender, from, to, tokens, fee,
            nonce);
        if (spender != ecrecoverFromSig(keccak256(signingPrefix, hash), sig))
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
        uint tokens, uint fee, uint nonce, bytes sig)
        public canTransfer returns (bool success)
    {
        // Check spender is the message signer
        bytes32 hash = signedTransferFromHash(spender, from, to, tokens,
            fee, nonce);
        require(spender == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

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
}


// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service Token Factory v1.00
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSTokenFactory is Owned, BTTSBase {

    // ------------------------------------------------------------------------
    // Constants used for signing and recovery
    // ------------------------------------------------------------------------
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";

    // ------------------------------------------------------------------------
    // signedDeployBTTSTokenContractSig(...) function signature
    // web3.sha3("signedDeployBTTSTokenContract(address,string,string,uint8,uint256,bool,bool,uint256,uint8,bytes32,bytes32)").substring(0,10)
    // => "cb0c3dc8"
    // ------------------------------------------------------------------------
    bytes4 public constant signedDeployBTTSTokenContractSig = "\xcb\x0c\x3d\xc8";

    // ------------------------------------------------------------------------
    // Executed signed calls
    // ------------------------------------------------------------------------
    mapping(address => mapping(bytes32 => bool)) public executed;

    // ------------------------------------------------------------------------
    // Internal data
    // ------------------------------------------------------------------------
    mapping(address => bool) _verify;

    address public baseToken;

    // ------------------------------------------------------------------------
    // Event
    // ------------------------------------------------------------------------
    event BTTSTokenListing(address indexed ownerAddress,
        address indexed bttsTokenAddress,
        string symbol, string name, uint8 decimals, 
        uint initialSupply, bool mintable, bool transferable);


    function BTTSTokenFactory() public {
    }

    function setBaseToken(address _baseToken) public {
        baseToken = _baseToken;
    }

    // ------------------------------------------------------------------------
    // Anyone can call this method to verify whether the bttsToken contract at
    // the specified address was deployed using this factory
    //
    // Parameters:
    //   tokenContract  the bttsToken contract address
    //
    // Return values:
    //   valid          did this BTTSTokenFactory create the BTTSToken contract?
    //   decimals       number of decimal places for the token contract
    //   initialSupply  the token initial supply
    //   mintable       is the token mintable after deployment?
    //   transferable   are the tokens transferable after deployment?
    // ------------------------------------------------------------------------
    function verify(address tokenContract) public constant returns (
        bool    valid,
        address owner,
        uint    decimals,
        bool    mintable,
        bool    transferable
    ) {
        valid = _verify[tokenContract];
        if (valid) {
            BTTSToken t = BTTSToken(tokenContract);
            owner        = t.owner();
            decimals     = t.decimals();
            mintable     = t.mintable();
            transferable = t.transferable();
        }
    }


    // ------------------------------------------------------------------------
    // Has a signed execution been executed?
    // ------------------------------------------------------------------------
    function alreadyExecuted(address deployer, bytes32 hash)
        public view returns (bool)
    {
        return executed[deployer][hash];
    }


    // ------------------------------------------------------------------------
    // Record a signed execution as having been executed
    // ------------------------------------------------------------------------
    function recordAsExecuted(address deployer, bytes32 hash) internal {
        executed[deployer][hash] = true;
    }


    // ------------------------------------------------------------------------
    // Any account can call this method to deploy a new BTTSToken contract.
    // The owner of the BTTSToken contract will be the calling account
    //
    // Parameters:
    //   symbol         symbol
    //   name           name
    //   decimals       number of decimal places for the token contract
    //   initialSupply  the token initial supply
    //   mintable       is the token mintable after deployment?
    //   transferable   are the tokens transferable after deployment?
    //
    // For example, deploying a BTTSToken contract with `initialSupply` of
    // 1,000.000000000000000000 tokens:
    //   symbol         "ME"
    //   name           "My Token"
    //   decimals       18
    //   initialSupply  10000000000000000000000 = 1,000.000000000000000000
    //                  tokens
    //   mintable       can tokens be minted after deployment?
    //   transferable   are the tokens transferable after deployment?
    //
    // The BTTSTokenListing() event is logged with the following parameters
    //   owner          the account that execute this transaction
    //   symbol         symbol
    //   name           name
    //   decimals       number of decimal places for the token contract
    //   initialSupply  the token initial supply
    //   mintable       can tokens be minted after deployment?
    //   transferable   are the tokens transferable after deployment?
    // ------------------------------------------------------------------------
    function deployBTTSTokenContract(
        string symbol,
        string name,
        uint8 decimals, 
        uint initialSupply,
        bool mintable,
        bool transferable
    ) public returns (address bttsTokenAddress) {
        bttsTokenAddress = new BTTSToken(
            symbol,
            name,
            decimals,
            initialSupply,
            mintable,
            transferable);
        // Record that this factory created the trader
        _verify[bttsTokenAddress] = true;
        // Transfer ownership to the account that deployed the contract
        BTTSToken(bttsTokenAddress).transferOwnershipImmediately(msg.sender);
        BTTSTokenListing(msg.sender, bttsTokenAddress, symbol, name, decimals, 
            initialSupply, mintable, transferable);
    }


    // ------------------------------------------------------------------------
    // signedDeployBTTSTokenContractHash functions
    //
    // Generate the hash used to create the signed
    //   deployBTTSTokenContractHash message
    // ------------------------------------------------------------------------
    function signedDeployBTTSTokenContractHash(
        string symbol,
        string name,
        uint8 decimals, 
        uint initialSupply,
        bool mintable,
        bool transferable,
        uint fee,
        uint nonce
    ) public view returns (bytes32 hash) {
        hash = keccak256(signedDeployBTTSTokenContractSig, address(this),
            symbol, name, decimals, initialSupply, mintable, transferable,
            fee, nonce);
    }

    // ------------------------------------------------------------------------
    // Check whether a signedDeployBTTSTokenContractHash can be executed on
    // behalf of the signing account of the message
    // ------------------------------------------------------------------------
    function signedDeployBTTSTokenContractCheck(
        address deployer,
        string symbol,
        string name,
        uint8 decimals, 
        uint initialSupply,
        bool mintable,
        bool transferable,
        uint fee,
        uint nonce,
        bytes sig)
        public constant returns (CheckResult result)
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check spender is the message signer
        bytes32 hash = signedDeployBTTSTokenContractHash(symbol, name, decimals,
            initialSupply, mintable, transferable, fee, nonce);
        if (deployer != ecrecoverFromSig(keccak256(signingPrefix, hash), sig))
            return CheckResult.SignerMismatch;

        // Check message not already executed
        if (alreadyExecuted(deployer, hash)) return CheckResult.AlreadyExecuted;

        /*
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
        */
        return CheckResult.Success;
    }


    // ------------------------------------------------------------------------
    // Execute a transferFrom on behalf of the user who signed the transferFrom 
    // message
    // ------------------------------------------------------------------------
    function signedDeployBTTSTokenContract(
        address deployer,
        string symbol,
        string name,
        uint8 decimals, 
        uint initialSupply,
        bool mintable,
        bool transferable,
        uint fee,
        uint nonce,
        bytes sig)
        public returns (bool success)
    {
        // Check spender is the message signer
        bytes32 hash = signedDeployBTTSTokenContractHash(symbol, name,
          decimals, initialSupply, mintable, transferable, fee, nonce);
        require(deployer == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

        // Check message not already executed
        // require(!executed[deployer][hash]);
        require(!alreadyExecuted(deployer, hash));
        // executed[deployer][hash] = true;
        recordAsExecuted(deployer, hash);

        require(ERC20Interface(baseToken).balanceOf(deployer) >= fee);
        require(ERC20Interface(baseToken).allowance(deployer, this) >= fee);
        /*
        require(allowed[from][spender] >= fee);

        // Move the tokens and fees
        balances[from] = balances[from].sub(fee);
        allowed[from][spender] = allowed[from][spender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);

        // Fee
        balances[from] = balances[from].sub(fee);
        allowed[from][spender] = allowed[from][spender].sub(fee);
        balances[msg.sender] = balances[msg.sender].add(fee);
        Transfer(from, msg.sender, fee);
        */

        return true;
    }


    // ------------------------------------------------------------------------
    // Factory owner can transfer out any accidentally sent ERC20 tokens
    //
    // Parameters:
    //   tokenAddress  contract address of the token contract being withdrawn
    //                 from
    //   tokens        number of tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens)
      public onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }


    // ------------------------------------------------------------------------
    // Don't accept ethers - no payable modifier
    // ------------------------------------------------------------------------
    function () public {
    }
}
