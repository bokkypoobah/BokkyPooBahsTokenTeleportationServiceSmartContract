pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
// BTTS 'BokkyPooBah's Token Teleportation Service' token interface and
// sample implementation
//
// See 
// https://github.com/bokkypoobah/BokkyPooBahsTokenTeleportationServiceSmartContract
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) public pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }

    // ------------------------------------------------------------------------
    // Subtract a number from another number, checking for underflows
    // ------------------------------------------------------------------------
    function sub(uint a, uint b) public pure returns (uint) {
        require(b <= a);
        return a - b;
    }

    // ------------------------------------------------------------------------
    // Multiply two numbers
    // ------------------------------------------------------------------------
    function mul(uint a, uint b) public pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    // ------------------------------------------------------------------------
    // Divide one number by another number
    // ------------------------------------------------------------------------
    function div(uint a, uint b) public pure returns (uint) {
        require(b > 0);
        uint c = a / b;
        return c;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    // The following function is an addition over the ERC20 standard
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
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
    // Constant used for recovery
    // ------------------------------------------------------------------------
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";


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
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // 
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(bytes32 hash, bytes sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65)
          return 0;

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
        }

        // albeit non-transactional signatures are not specified by the YP, one would expect it
        // to match the YP range of [27, 28]
        //
        // geth uses [0, 1] and some clients have followed. This might change, see:
        //  https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27)
          v += 27;

        if (v != 27 && v != 28)
            return 0;

        return ecrecover(hash, v, r, s);
    }


    // ------------------------------------------------------------------------
    // Get CheckResult message
    // ------------------------------------------------------------------------
    function getCheckResultMessage(CheckResult result) public pure
        returns (string) {
        if (result == CheckResult.Success) {
            return "Success";
        } else if (result == CheckResult.NotTransferable) {
            return "Tokens not transferable yet";
        } else if (result == CheckResult.SignerMismatch) {
            return "Mismatch in signing account";
        } else if (result == CheckResult.AlreadyExecuted) {
            return "Transfer already executed";
        } else if (result == CheckResult.InsufficientApprovedTokens) {
            return "Insufficient approved tokens";
        } else if (result == CheckResult.InsufficientApprovedTokensForFees) {
            return "Insufficient approved tokens for fees";
        } else if (result == CheckResult.InsufficientTokens) {
            return "Insufficient tokens";
        } else if (result == CheckResult.InsufficientTokensForFees) {
            return "Insufficient tokens for fees";
        } else if (result == CheckResult.OverflowError) {
            return "Overflow error";
        } else {
            return "Unknown error";
        }
    }
}


// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service (BTTS) Interface v1.00
//
// This consist of the signed message versions of the three ERC20 function:
// - signedTransfer(...)
// - signedApprove(...)
// - signedTransferFrom(...)
// - signedApproveAndCall(...)
//
// Each of these signed message functions have a helper to generate the signed
// message hash:
// - signedTransferHash(...)
// - signedApproveHash(...)
// - signedTransferFromHash(...)
// - signedApproveAndCallHash(...)
//
// Each of these signed message functions have a helper function to check
// the status of the signed message before the signed message functions are
// submitted for execution:
// - signedTransferCheck(...)
// - signedApproveCheck(...)
// - signedTransferFromCheck(...)
// - signedApproveAndCallCheck(...)
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSInterface is BTTSBase {

    // ------------------------------------------------------------------------
    // Constants used for recovery
    //
    // signedTransfer(...) function signature
    // web3.sha3("signedTransfer(address,address,uint256,uint256,uint256,bytes,address)").substring(0,10)
    // => "0x7532eaac"
    // ------------------------------------------------------------------------
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";

    // ------------------------------------------------------------------------
    // signedApprove(...) function signature
    // web3.sha3("signedApprove(address,address,uint256,uint256,uint256,bytes,address)").substring(0,10)
    // => "0xe9afa7a1"
    // ------------------------------------------------------------------------
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";

    // ------------------------------------------------------------------------
    // signedTransferFrom(...) function signature
    // web3.sha3("signedTransferFrom(address,address,address,uint256,uint256,uint256,bytes,address)").substring(0,10)
    // => "0x344bcc7d"
    // ------------------------------------------------------------------------
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";

    // ------------------------------------------------------------------------
    // signedApproveAndCall(...) function signature
    // web3.sha3("signedApproveAndCall(address,address,uint256,bytes,uint256,uint256,bytes,address)").substring(0,10)
    // => "0xf16f9b53"
    // ------------------------------------------------------------------------
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";


    // ------------------------------------------------------------------------
    // signedTransfer functions
    //
    // Generate the hash used to create the signed transfer message
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens,
        uint fee, uint nonce) public view returns (bytes32 hash);

    // ------------------------------------------------------------------------
    // Check whether a transfer can be executed on behalf of the user who
    // signed the transfer message
    // ------------------------------------------------------------------------
    function signedTransferCheck(address tokenOwner, address to, uint tokens,
        uint fee, uint nonce, bytes sig, address feeAccount)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute a transfer on behalf of the user who signed the transfer 
    // message
    // ------------------------------------------------------------------------
    function signedTransfer(address tokenOwner, address to, uint tokens,
        uint fee, uint nonce, bytes sig, address feeAccount)
        public returns (bool success);


    // ------------------------------------------------------------------------
    // signedApprove functions
    //
    // Generate the hash used to create the signed approve message
    // ------------------------------------------------------------------------
    function signedApproveHash(address tokenOwner, address spender,
        uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);

    // ------------------------------------------------------------------------
    // Check whether an approve can be executed on behalf of the user who
    // signed the approve message
    // ------------------------------------------------------------------------
    function signedApproveCheck(address tokenOwner, address spender,
        uint tokens, uint fee, uint nonce, bytes sig, address feeAccount)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute an approve on behalf of the user who signed the approve message
    // ------------------------------------------------------------------------
    function signedApprove(address tokenOwner, address spender, uint tokens,
        uint fee, uint nonce, bytes sig, address feeAccount)
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
        uint tokens, uint fee, uint nonce, bytes sig, address feeAccount)
        public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute a transferFrom on behalf of the user who signed the transferFrom 
    // message
    // ------------------------------------------------------------------------
    function signedTransferFrom(address spender, address from, address to,
        uint tokens, uint fee, uint nonce, bytes sig, address feeAccount)
        public returns (bool success);


    // ------------------------------------------------------------------------
    // signedApproveAndCall functions
    //
    // Generate the hash used to create the signed approve message
    // ------------------------------------------------------------------------
    function signedApproveAndCallHash(address tokenOwner, address spender,
        uint tokens, bytes data, uint fee, uint nonce)
        public view returns (bytes32 hash);

    // ------------------------------------------------------------------------
    // Check whether an approve can be executed on behalf of the user who
    // signed the approve message
    // ------------------------------------------------------------------------
    function signedApproveAndCallCheck(address tokenOwner, address spender,
        uint tokens, bytes data, uint fee, uint nonce, bytes sig,
        address feeAccount) public constant returns (CheckResult result);

    // ------------------------------------------------------------------------
    // Execute an approve on behalf of the user who signed the approve message
    // ------------------------------------------------------------------------
    function signedApproveAndCall(address tokenOwner, address spender,
        uint tokens, bytes data, uint fee, uint nonce, bytes sig,
        address feeAccount) public returns (bool success);
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
    function Owned(address _owner) public {
        owner = _owner;
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
        newOwner = address(0);
    }

    // ------------------------------------------------------------------------
    // Owner can initiate transfer of contract to a new owner
    // ------------------------------------------------------------------------
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
        newOwner = address(0);
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
    uint public _totalSupply;

    // ------------------------------------------------------------------------
    // Token contract state
    // ------------------------------------------------------------------------
    bool public mintable;
    bool public transferable;
    address public minter;

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
    // Events
    // ------------------------------------------------------------------------
    event MinterUpdated(address from, address to);
    event MintingDisabled();
    event TransfersEnabled();


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function ERC20Token(address _owner, string _symbol, string _name,
        uint8 _decimals, uint _initialSupply, bool _mintable,
        bool _transferable) public Owned(_owner) 
    {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        decimalsFactor = 10**uint(_decimals);
        if (_initialSupply > 0) {
            balances[_owner] = _initialSupply;
            _totalSupply = _initialSupply;
            Transfer(address(0), _owner, _initialSupply);
        }
        mintable = _mintable;
        transferable = _transferable;
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }


    // ------------------------------------------------------------------------
    // Set Minter
    // ------------------------------------------------------------------------
    function setMinter(address _minter) public onlyOwner {
        require(mintable);
        MinterUpdated(minter, _minter);
        minter = _minter;
    }


    // ------------------------------------------------------------------------
    // Disable minting
    // ------------------------------------------------------------------------
    function disableMinting() public onlyOwner {
        require(mintable);
        mintable = false;
        if (minter != address(0)) {
            MinterUpdated(minter, address(0));
            minter = address(0);
            MintingDisabled();
        }
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
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner)
        public constant returns (uint balance)
    {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        // Owner and minter can move tokens before the tokens are transferable 
        require(transferable || (mintable &&
            (msg.sender == owner  || msg.sender == minter)));

        // Perform the tranfers
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);

        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens)
        public returns (bool success) 
    {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens)
        public returns (bool success)
    {
        // Can we transfer
        require(transferable);

        // Perform the transfers
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
    function allowance(address tokenOwner, address spender)
        public constant returns (uint remaining)
    {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data)
        public returns (bool success) 
    {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens,
            this, data);

        return true;
    }


    // ------------------------------------------------------------------------
    // Mint tokens - internal
    // ------------------------------------------------------------------------
    function mintInternal(address tokenOwner, uint tokens)
        internal returns (bool success)
    {
        // Check we are in the minting stage
        require(mintable);

        // Mint the tokens
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        Transfer(address(0), tokenOwner, tokens);

        return true;
    }


    // ------------------------------------------------------------------------
    // Mint tokens
    // ------------------------------------------------------------------------
    function mint(address tokenOwner, uint tokens)
        public returns (bool success)
    {
        // Only the minter or the owner can mint
        require(msg.sender == minter || msg.sender == owner);

        return mintInternal(tokenOwner, tokens);
    }


    // ------------------------------------------------------------------------
    // Don't accept ethers
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
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
    // Constructor
    // ------------------------------------------------------------------------
    function BTTSToken(address _owner, string _symbol, string _name,
        uint8 _decimals, uint _initialSupply, bool _mintable,
        bool _transferable) public ERC20Token(_owner, _symbol, _name,
        _decimals, _initialSupply, _mintable, _transferable)
    {
    }


    // ------------------------------------------------------------------------
    // signedTransfer functions
    //
    // Generate the hash used to create the signed transfer message
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens,
        uint fee, uint nonce) public view returns (bytes32 hash)
    {
        hash = keccak256(signedTransferSig, address(this), tokenOwner, to,
            tokens, fee, nonce);
    }

    // ------------------------------------------------------------------------
    // Check whether a transfer can be executed on behalf of the user who
    // signed the transfer message
    // ------------------------------------------------------------------------
    function signedTransferCheck(address tokenOwner, address to, uint tokens,
        uint fee, uint nonce, bytes sig, address feeAccount)
        public constant returns (CheckResult result)
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check tokenOwner is the message signer
        bytes32 hash = signedTransferHash(tokenOwner, to, tokens, fee, nonce);
        if (tokenOwner != ecrecoverFromSig(keccak256(signingPrefix, hash), sig))
            return CheckResult.SignerMismatch;

        // Check message not already executed
        if (executed[tokenOwner][hash]) return CheckResult.AlreadyExecuted;

        uint total = tokens.add(fee);

        // Check there are sufficient tokens to transfer
        if (balances[tokenOwner] < tokens) return CheckResult.InsufficientTokens;

        // Check there are sufficient tokens to pay for fees
        if (balances[tokenOwner] < total)
            return CheckResult.InsufficientTokensForFees;

        // Check for overflows
        if (balances[to] + tokens < balances[to])
            return CheckResult.OverflowError;
        if (balances[feeAccount] + fee < balances[feeAccount])
            return CheckResult.OverflowError;

        return CheckResult.Success;
    }

    // ------------------------------------------------------------------------
    // Execute a transfer on behalf of the user who signed the transfer
    // message
    // ------------------------------------------------------------------------
    function signedTransfer(address tokenOwner, address to, uint tokens,
        uint fee, uint nonce, bytes sig, address feeAccount)
        public returns (bool success)
    {
        require(transferable);

        // Check tokenOwner is the message signer
        bytes32 hash = signedTransferHash(tokenOwner, to, tokens, fee, nonce);
        require(tokenOwner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

        // Check message not already executed
        require(!executed[tokenOwner][hash]);
        executed[tokenOwner][hash] = true;

        // Move the tokens
        balances[tokenOwner] = balances[tokenOwner].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(tokenOwner, to, tokens);

        // Fee
        balances[tokenOwner] = balances[tokenOwner].sub(fee);
        balances[feeAccount] = balances[feeAccount].add(fee);
        Transfer(tokenOwner, feeAccount, fee);

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
    function signedApproveCheck(address tokenOwner, address spender,
        uint tokens, uint fee, uint nonce, bytes sig, address feeAccount)
        public constant returns (CheckResult result) 
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check tokenOwner is the message signer
        bytes32 hash = signedApproveHash(tokenOwner, spender, tokens, fee, nonce);
        if (tokenOwner != ecrecoverFromSig(keccak256(signingPrefix, hash), sig))
            return CheckResult.SignerMismatch;

        // Check message not already executed
        if (executed[tokenOwner][hash]) return CheckResult.AlreadyExecuted;

        // Check there are sufficient tokens to pay for fees
        if (balances[tokenOwner] < fee)
            return CheckResult.InsufficientTokensForFees;

        // Check for overflows
        if (balances[feeAccount] + fee < balances[feeAccount])
            return CheckResult.OverflowError;

        return CheckResult.Success;
    }

    // ------------------------------------------------------------------------
    // Execute an approve on behalf of the user who signed the approve message
    // ------------------------------------------------------------------------
    function signedApprove(address tokenOwner, address spender, uint tokens,
        uint fee, uint nonce, bytes sig, address feeAccount)
        public returns (bool success) 
    {
        require(transferable);

        // Check tokenOwner is the message signer
        bytes32 hash = signedApproveHash(tokenOwner, spender, tokens, fee, nonce);
        require(tokenOwner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

        // Check message not already executed
        require(!executed[tokenOwner][hash]);
        executed[tokenOwner][hash] = true;

        // Approve
        allowed[tokenOwner][spender] = tokens;
        Approval(tokenOwner, spender, tokens);

        // Fee
        balances[tokenOwner] = balances[tokenOwner].sub(fee);
        balances[feeAccount] = balances[feeAccount].add(fee);
        Transfer(tokenOwner, feeAccount, fee);

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
        uint tokens, uint fee, uint nonce, bytes sig, address feeAccount)
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
        if (balances[feeAccount] + fee < balances[feeAccount])
            return CheckResult.OverflowError;

        return CheckResult.Success;
    }


    // ------------------------------------------------------------------------
    // Execute a transferFrom on behalf of the user who signed the transferFrom 
    // message
    // ------------------------------------------------------------------------
    function signedTransferFrom(address spender, address from, address to,
        uint tokens, uint fee, uint nonce, bytes sig, address feeAccount)
        public returns (bool success)
    {
        require(transferable);

        // Check spender is the message signer
        bytes32 hash = signedTransferFromHash(spender, from, to, tokens,
            fee, nonce);
        require(spender == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

        // Check message not already executed
        require(!executed[spender][hash]);
        executed[spender][hash] = true;

        // Move the tokens and fees
        balances[from] = balances[from].sub(tokens);
        allowed[from][spender] = allowed[from][spender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);

        // Fee
        balances[from] = balances[from].sub(fee);
        allowed[from][spender] = allowed[from][spender].sub(fee);
        balances[feeAccount] = balances[feeAccount].add(fee);
        Transfer(from, feeAccount, fee);

        return true;
    }


    // ------------------------------------------------------------------------
    // signedApproveAndCall functions
    //
    // Generate the hash used to create the signed approve message
    // ------------------------------------------------------------------------
    function signedApproveAndCallHash(address signer, address spender,
        uint tokens, bytes data, uint fee, uint nonce)
        public view returns (bytes32 hash) 
    {
        hash = keccak256(signedApproveAndCallSig, address(this),
            signer, spender, tokens, data, fee, nonce);
    }

    // ------------------------------------------------------------------------
    // Check whether an approveAndCall can be executed on behalf of the user
    // who signed the approve message
    // ------------------------------------------------------------------------
    function signedApproveAndCallCheck(address tokenOwner, address spender,
        uint tokens, bytes data, uint fee, uint nonce, bytes sig,
        address feeAccount) public constant returns (CheckResult result) 
    {
        // Check tokens are transferable
        if (!transferable) return CheckResult.NotTransferable;

        // Check tokenOwner is the message signer
        bytes32 hash = signedApproveAndCallHash(tokenOwner, spender, tokens,
            data, fee, nonce);
        if (tokenOwner != ecrecoverFromSig(keccak256(signingPrefix, hash), sig))
            return CheckResult.SignerMismatch;

        // Check message not already executed
        if (executed[tokenOwner][hash]) return CheckResult.AlreadyExecuted;

        // Check there are sufficient tokens to pay for fees
        if (balances[tokenOwner] < fee)
            return CheckResult.InsufficientTokensForFees;

        // Check for overflows
        if (balances[feeAccount] + fee < balances[feeAccount])
            return CheckResult.OverflowError;

        return CheckResult.Success;
    }

    // ------------------------------------------------------------------------
    // Execute an approveAndCall on behalf of the user who signed the approve
    // message
    // ------------------------------------------------------------------------
    function signedApproveAndCall(address tokenOwner, address spender,
        uint tokens, bytes data, uint fee, uint nonce, bytes sig,
        address feeAccount) public returns (bool success) 
    {
        require(transferable);

        // Check tokenOwner is the message signer
        bytes32 hash = signedApproveAndCallHash(tokenOwner, spender, tokens,
            data, fee, nonce);
        require(tokenOwner == ecrecoverFromSig(keccak256(signingPrefix, hash), sig));

        // Check message not already executed
        require(!executed[tokenOwner][hash]);
        executed[tokenOwner][hash] = true;

        // Approve
        allowed[tokenOwner][spender] = tokens;
        Approval(tokenOwner, spender, tokens);

        // Fee
        balances[tokenOwner] = balances[tokenOwner].sub(fee);
        balances[feeAccount] = balances[feeAccount].add(fee);
        Transfer(tokenOwner, feeAccount, fee);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens,
            this, data);

        return true;
    }
}


// ----------------------------------------------------------------------------
// BokkyPooBah's Token Teleportation Service Token Factory v1.00
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
// ----------------------------------------------------------------------------
contract BTTSTokenFactory is Owned {

    // ------------------------------------------------------------------------
    // Internal data
    // ------------------------------------------------------------------------
    mapping(address => bool) _verify;

    // ------------------------------------------------------------------------
    // Event
    // ------------------------------------------------------------------------
    event BTTSTokenListing(address indexed ownerAddress,
        address indexed bttsTokenAddress, 
        string symbol, string name, uint8 decimals, 
        uint initialSupply, bool mintable, bool transferable);


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function BTTSTokenFactory() public Owned(msg.sender) {
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
            msg.sender,
            symbol,
            name,
            decimals,
            initialSupply,
            mintable,
            transferable);
        // Record that this factory created the trader
        _verify[bttsTokenAddress] = true;
        BTTSTokenListing(msg.sender, bttsTokenAddress, symbol, name, decimals, 
            initialSupply, mintable, transferable);
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
    // Don't accept ethers
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}