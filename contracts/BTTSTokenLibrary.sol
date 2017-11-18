pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) public pure returns (uint) {
        uint c = a + b;
        require(c >= a);
        return c;
    }
    function sub(uint a, uint b) public pure returns (uint) {
        require(b <= a);
        return a - b;
    }
    function mul(uint a, uint b) public pure returns (uint) {
        uint c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }
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
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract BTTSInterface is ERC20Interface {
    uint public constant bttsVersion = 100;

    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";

    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success);

    // ------------------------------------------------------------------------
    // signed{X} functions
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (CheckResult result);
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveHash(address tokenOwner, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (CheckResult result);
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (CheckResult result);
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

    function signedApproveAndCallHash(address tokenOwner, address spender, uint tokens, bytes data, uint fee, uint nonce) public view returns (bytes32 hash);
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes data, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (CheckResult result);
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success);

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
}


library BTTSLib {
    using SafeMath for uint;

    struct Data {
        // Ownership
        address owner;
        address newOwner;
        address minter;

        // Token
        string symbol;
        string name;
        uint8 decimals;
        uint decimalsFactor;
        uint totalSupply;
        
        bool mintable;
        bool transferable;

        mapping(address => uint) balances;
        mapping(address => mapping(address => uint)) allowed;
        mapping(address => mapping(bytes32 => bool)) executed;
    }


    // ------------------------------------------------------------------------
    // Constants
    // ------------------------------------------------------------------------
    uint public constant bttsVersion = 100;
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";
    bytes4 public constant signedTransferSig = "\x75\x32\xea\xac";
    bytes4 public constant signedApproveSig = "\xe9\xaf\xa7\xa1";
    bytes4 public constant signedTransferFromSig = "\x34\x4b\xcc\x7d";
    bytes4 public constant signedApproveAndCallSig = "\xf1\x6f\x9b\x53";

    // ------------------------------------------------------------------------
    // Event
    // ------------------------------------------------------------------------
    event OwnershipTransferred(address indexed from, address indexed to);
    event MinterUpdated(address from, address to);
    event MintingDisabled();
    event TransfersEnabled();
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    // ------------------------------------------------------------------------
    // Initialisation
    // ------------------------------------------------------------------------
    function init(Data storage self, address owner, string symbol, string name, uint8 decimals, uint initialSupply, bool mintable, bool transferable) public {
        self.owner = owner;
        self.symbol = symbol;
        self.name = name;
        self.decimals = decimals;
        self.decimalsFactor = 10**uint(decimals);
        if (initialSupply > 0) {
            self.balances[owner] = initialSupply;
            self.totalSupply = initialSupply;
            Transfer(address(0), self.owner, initialSupply);
        }
        self.mintable = mintable;
        self.transferable = transferable;
    }


    // ------------------------------------------------------------------------
    // Ownership
    // ------------------------------------------------------------------------
    function transferOwnership(Data storage self, address newOwner) public {
        require(msg.sender == self.owner);
        self.newOwner = newOwner;
    }
    function acceptOwnership(Data storage self) public {
        require(msg.sender == self.newOwner);
        OwnershipTransferred(self.owner, self.newOwner);
        self.owner = self.newOwner;
        self.newOwner = address(0);
    }
    function transferOwnershipImmediately(Data storage self, address newOwner) public {
        require(msg.sender == self.owner);
        OwnershipTransferred(self.owner, newOwner);
        self.owner = newOwner;
        self.newOwner = address(0);
    }
    function setMinter(Data storage self, address minter) public {
        require(msg.sender == self.owner);
        require(self.mintable);
        MinterUpdated(self.minter, minter);
        self.minter = minter;
    }

    // ------------------------------------------------------------------------
    // Disable minting and enable transfers
    // ------------------------------------------------------------------------
    function disableMinting(Data storage self) public {
        require(msg.sender == self.owner);
        require(self.mintable);
        self.mintable = false;
        if (self.minter != address(0)) {
            MinterUpdated(self.minter, address(0));
            self.minter = address(0);
        }
        MintingDisabled();
    }
    function enableTransfers(Data storage self) public {
        require(msg.sender == self.owner);
        require(!self.transferable);
        self.transferable = true;
        TransfersEnabled();
    }

    // ------------------------------------------------------------------------
    // Other functions
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(Data storage self, address tokenAddress, uint tokens) public returns (bool success) {
        require(msg.sender == self.owner);
        return ERC20Interface(tokenAddress).transfer(self.owner, tokens);
    }

    // ------------------------------------------------------------------------
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // The signature format is a compact form {bytes32 r}{bytes32 s}{uint8 v}.
    // Compact means, uint8 is not padded to 32 bytes.
    // 
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(Data storage /*self*/, bytes32 hash, bytes sig) public pure returns (address recoveredAddress) {
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
        //
        // geth uses [0, 1] and some clients have followed. This might change, see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }

    // ------------------------------------------------------------------------
    // Get CheckResult message
    // ------------------------------------------------------------------------
    function getCheckResultMessage(Data storage /*self*/, BTTSInterface.CheckResult result) public pure
        returns (string) {
        if (result == BTTSInterface.CheckResult.Success) {
            return "Success";
        } else if (result == BTTSInterface.CheckResult.NotTransferable) {
            return "Tokens not transferable yet";
        } else if (result == BTTSInterface.CheckResult.SignerMismatch) {
            return "Mismatch in signing account";
        } else if (result == BTTSInterface.CheckResult.AlreadyExecuted) {
            return "Transfer already executed";
        } else if (result == BTTSInterface.CheckResult.InsufficientApprovedTokens) {
            return "Insufficient approved tokens";
        } else if (result == BTTSInterface.CheckResult.InsufficientApprovedTokensForFees) {
            return "Insufficient approved tokens for fees";
        } else if (result == BTTSInterface.CheckResult.InsufficientTokens) {
            return "Insufficient tokens";
        } else if (result == BTTSInterface.CheckResult.InsufficientTokensForFees) {
            return "Insufficient tokens for fees";
        } else if (result == BTTSInterface.CheckResult.OverflowError) {
            return "Overflow error";
        } else {
            return "Unknown error";
        }
    }
    
    // ------------------------------------------------------------------------
    // Token functions
    // ------------------------------------------------------------------------
    function transfer(Data storage self, address to, uint tokens) public returns (bool success) {
        // Owner and minter can move tokens before the tokens are transferable 
        require(self.transferable || (self.mintable && (msg.sender == self.owner  || msg.sender == self.minter)));
        self.balances[msg.sender] = self.balances[msg.sender].sub(tokens);
        self.balances[to] = self.balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
    function approve(Data storage self, address spender, uint tokens) public returns (bool success) {
        self.allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
    function transferFrom(Data storage self, address from, address to, uint tokens) public returns (bool success) {
        require(self.transferable);
        self.balances[from] = self.balances[from].sub(tokens);
        self.allowed[from][msg.sender] = self.allowed[from][msg.sender].sub(tokens);
        self.balances[to] = self.balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
    function approveAndCall(Data storage self, address tokenContract, address spender, uint tokens, bytes data) public returns (bool success) {
        self.allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, tokenContract, data);
        return true;
    }
    function mint(Data storage self, address tokenOwner, uint tokens) internal returns (bool success) {
        require(self.mintable);
        require(msg.sender == self.minter || msg.sender == self.owner);
        self.balances[tokenOwner] = self.balances[tokenOwner].add(tokens);
        self.totalSupply = self.totalSupply.add(tokens);
        Transfer(address(0), tokenOwner, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Signed function
    // ------------------------------------------------------------------------
    function signedTransferHash(Data storage /*self*/, address tokenContract, address tokenOwner, address to, uint tokens, uint fee, uint nonce) public pure returns (bytes32 hash) {
        hash = keccak256(signedTransferSig, tokenContract, tokenOwner, to, tokens, fee, nonce);
    }
    function signedTransferCheck(Data storage self, address tokenContract, address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (BTTSInterface.CheckResult result) {
        if (!self.transferable) return BTTSInterface.CheckResult.NotTransferable;
        bytes32 hash = signedTransferHash(self, tokenContract, tokenOwner, to, tokens, fee, nonce);
        if (tokenOwner == address(0) || tokenOwner != ecrecoverFromSig(self, keccak256(signingPrefix, hash), sig)) return BTTSInterface.CheckResult.SignerMismatch;
        if (self.executed[tokenOwner][hash]) return BTTSInterface.CheckResult.AlreadyExecuted;
        uint total = tokens.add(fee);
        if (self.balances[tokenOwner] < tokens) return BTTSInterface.CheckResult.InsufficientTokens;
        if (self.balances[tokenOwner] < total) return BTTSInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[to] + tokens < self.balances[to]) return BTTSInterface.CheckResult.OverflowError;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return BTTSInterface.CheckResult.OverflowError;
        return BTTSInterface.CheckResult.Success;
    }
    function signedTransfer(Data storage self, address tokenContract, address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedTransferHash(self, tokenContract, tokenOwner, to, tokens, fee, nonce);
        require(tokenOwner != address(0) && tokenOwner == ecrecoverFromSig(self, keccak256(signingPrefix, hash), sig));
        require(!self.executed[tokenOwner][hash]);
        self.executed[tokenOwner][hash] = true;
        self.balances[tokenOwner] = self.balances[tokenOwner].sub(tokens);
        self.balances[to] = self.balances[to].add(tokens);
        Transfer(tokenOwner, to, tokens);
        self.balances[tokenOwner] = self.balances[tokenOwner].sub(fee);
        self.balances[feeAccount] = self.balances[feeAccount].add(fee);
        Transfer(tokenOwner, feeAccount, fee);
        return true;
    }
    function signedApproveHash(Data storage /*self*/, address tokenContract, address signer, address spender, uint tokens, uint fee, uint nonce) public pure returns (bytes32 hash) {
        hash = keccak256(signedApproveSig, tokenContract, signer, spender, tokens, fee, nonce);
    }
    function signedApproveCheck(Data storage self, address tokenContract, address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (BTTSInterface.CheckResult result) {
        if (!self.transferable) return BTTSInterface.CheckResult.NotTransferable;
        bytes32 hash = signedApproveHash(self, tokenContract, tokenOwner, spender, tokens, fee, nonce);
        if (tokenOwner == address(0) || tokenOwner != ecrecoverFromSig(self, keccak256(signingPrefix, hash), sig)) return BTTSInterface.CheckResult.SignerMismatch;
        if (self.executed[tokenOwner][hash]) return BTTSInterface.CheckResult.AlreadyExecuted;
        if (self.balances[tokenOwner] < fee) return BTTSInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return BTTSInterface.CheckResult.OverflowError;
        return BTTSInterface.CheckResult.Success;
    }
    function signedApprove(Data storage self, address tokenContract, address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedApproveHash(self, tokenContract, tokenOwner, spender, tokens, fee, nonce);
        require(tokenOwner != address(0) && tokenOwner == ecrecoverFromSig(self, keccak256(signingPrefix, hash), sig));
        require(!self.executed[tokenOwner][hash]);
        self.executed[tokenOwner][hash] = true;
        self.allowed[tokenOwner][spender] = tokens;
        Approval(tokenOwner, spender, tokens);
        self.balances[tokenOwner] = self.balances[tokenOwner].sub(fee);
        self.balances[feeAccount] = self.balances[feeAccount].add(fee);
        Transfer(tokenOwner, feeAccount, fee);
        return true;
    }
    function signedTransferFromHash(Data storage /*self*/, address tokenContract, address spender, address from, address to, uint tokens, uint fee, uint nonce) public pure returns (bytes32 hash) {
        hash = keccak256(signedTransferFromSig, tokenContract, spender, from, to, tokens, fee, nonce);
    }
    function signedTransferFromCheck(Data storage self, address tokenContract, address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (BTTSInterface.CheckResult result) {
        if (!self.transferable) return BTTSInterface.CheckResult.NotTransferable;
        bytes32 hash = signedTransferFromHash(self, tokenContract, spender, from, to, tokens, fee, nonce);
        if (spender == address(0) || spender != ecrecoverFromSig(self, keccak256(signingPrefix, hash), sig)) return BTTSInterface.CheckResult.SignerMismatch;
        if (self.executed[spender][hash]) return BTTSInterface.CheckResult.AlreadyExecuted;
        uint total = tokens.add(fee);
        if (self.allowed[from][spender] < tokens) return BTTSInterface.CheckResult.InsufficientApprovedTokens;
        if (self.allowed[from][spender] < total) return BTTSInterface.CheckResult.InsufficientApprovedTokensForFees;
        if (self.balances[from] < tokens) return BTTSInterface.CheckResult.InsufficientTokens;
        if (self.balances[from] < total) return BTTSInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[to] + tokens < self.balances[to]) return BTTSInterface.CheckResult.OverflowError;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return BTTSInterface.CheckResult.OverflowError;
        return BTTSInterface.CheckResult.Success;
    }
    function signedTransferFrom(Data storage self, address tokenContract, address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedTransferFromHash(self, tokenContract, spender, from, to, tokens, fee, nonce);
        require(spender != address(0) && spender == ecrecoverFromSig(self, keccak256(signingPrefix, hash), sig));
        require(!self.executed[spender][hash]);
        self.executed[spender][hash] = true;
        self.balances[from] = self.balances[from].sub(tokens);
        self.allowed[from][spender] = self.allowed[from][spender].sub(tokens);
        self.balances[to] = self.balances[to].add(tokens);
        Transfer(from, to, tokens);
        self.balances[from] = self.balances[from].sub(fee);
        self.allowed[from][spender] = self.allowed[from][spender].sub(fee);
        self.balances[feeAccount] = self.balances[feeAccount].add(fee);
        Transfer(from, feeAccount, fee);
        return true;
    }
    function signedApproveAndCallHash(Data storage /*self*/, address tokenContract, address signer, address spender, uint tokens, bytes data, uint fee, uint nonce) public pure returns (bytes32 hash) {
        hash = keccak256(signedApproveAndCallSig, tokenContract, signer, spender, tokens, data, fee, nonce);
    }
    function signedApproveAndCallCheck(Data storage self, address tokenContract, address tokenOwner, address spender, uint tokens, bytes data, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (BTTSInterface.CheckResult result) {
        if (!self.transferable) return BTTSInterface.CheckResult.NotTransferable;
        bytes32 hash = signedApproveAndCallHash(self, tokenContract, tokenOwner, spender, tokens, data, fee, nonce);
        if (tokenOwner == address(0) || tokenOwner != ecrecoverFromSig(self, keccak256(signingPrefix, hash), sig)) return BTTSInterface.CheckResult.SignerMismatch;
        if (self.executed[tokenOwner][hash]) return BTTSInterface.CheckResult.AlreadyExecuted;
        if (self.balances[tokenOwner] < fee) return BTTSInterface.CheckResult.InsufficientTokensForFees;
        if (self.balances[feeAccount] + fee < self.balances[feeAccount]) return BTTSInterface.CheckResult.OverflowError;
        return BTTSInterface.CheckResult.Success;
    }
    function signedApproveAndCall(Data storage self, address tokenContract, address tokenOwner, address spender, uint tokens, bytes data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        require(self.transferable);
        bytes32 hash = signedApproveAndCallHash(self, tokenContract, tokenOwner, spender, tokens, data, fee, nonce);
        require(tokenOwner != address(0) && tokenOwner == ecrecoverFromSig(self, keccak256(signingPrefix, hash), sig));
        require(!self.executed[tokenOwner][hash]);
        self.executed[tokenOwner][hash] = true;
        self.allowed[tokenOwner][spender] = tokens;
        Approval(tokenOwner, spender, tokens);
        self.balances[tokenOwner] = self.balances[tokenOwner].sub(fee);
        self.balances[feeAccount] = self.balances[feeAccount].add(fee);
        Transfer(tokenOwner, feeAccount, fee);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, tokenContract, data);
        return true;
    }
}


contract BTTSToken is BTTSInterface {
    using BTTSLib for BTTSLib.Data;

    BTTSLib.Data data;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function BTTSToken(address owner, string symbol, string name, uint8 decimals, uint initialSupply, bool mintable, bool transferable) public {
        data.init(owner, symbol, name, decimals, initialSupply, mintable, transferable);
    }

    // ------------------------------------------------------------------------
    // Ownership
    // ------------------------------------------------------------------------
    function owner() public view returns (address) {
        return data.owner;
    }
    function newOwner() public view returns (address) {
        return data.newOwner;
    }
    function transferOwnership(address _newOwner) public {
        data.transferOwnership(_newOwner);
    }
    function acceptOwnership() public {
        data.acceptOwnership();
    }
    function transferOwnershipImmediately(address _newOwner) public {
        data.transferOwnershipImmediately(_newOwner);
    }
    function setMinter(address minter) public {
        data.setMinter(minter);
    }
    
    // ------------------------------------------------------------------------
    // Disable minting and enable transfers
    // ------------------------------------------------------------------------
    function disableMinting() public {
        data.disableMinting();
    }
    function enableTransfers() public {
        data.enableTransfers();
    }

    // ------------------------------------------------------------------------
    // Other functions
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool success) {
        return data.transferAnyERC20Token(tokenAddress, tokens);
    }

    // ------------------------------------------------------------------------
    // Don't accept ethers
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }

    // ------------------------------------------------------------------------
    // Token functions
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return data.totalSupply;
    }
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return data.balances[tokenOwner];
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return data.allowed[tokenOwner][spender];
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        return data.transfer(to, tokens);
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        return data.approve(spender, tokens);
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        return data.transferFrom(from, to, tokens);
    }
    function approveAndCall(address spender, uint tokens, bytes _data) public returns (bool success) {
        success = data.approveAndCall(this, spender, tokens, _data);
    }
    function mint(address tokenOwner, uint tokens) public returns (bool success) {
        return data.mint(tokenOwner, tokens);
    }

    // ------------------------------------------------------------------------
    // Signed function
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenOwner, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedTransferHash(address(this), tokenOwner, to, tokens, fee, nonce);
    }
    function signedTransferCheck(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (CheckResult result) {
        return data.signedTransferCheck(address(this), tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }
    function signedTransfer(address tokenOwner, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        return data.signedTransfer(address(this), tokenOwner, to, tokens, fee, nonce, sig, feeAccount);
    }
    function signedApproveHash(address signer, address spender, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedApproveHash(address(this), signer, spender, tokens, fee, nonce);
    }
    function signedApproveCheck(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (CheckResult result) {
        return data.signedApproveCheck(address(this), tokenOwner, spender, tokens, fee, nonce, sig, feeAccount);
    }
    function signedApprove(address tokenOwner, address spender, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        return data.signedApprove(address(this), tokenOwner, spender, tokens, fee, nonce, sig, feeAccount);
    }
    function signedTransferFromHash(address spender, address from, address to, uint tokens, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedTransferFromHash(address(this), spender, from, to, tokens, fee, nonce);
    }
    function signedTransferFromCheck(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (CheckResult result) {
        return data.signedTransferFromCheck(address(this), spender, from, to, tokens, fee, nonce, sig, feeAccount);
    }
    function signedTransferFrom(address spender, address from, address to, uint tokens, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        return data.signedTransferFrom(address(this), spender, from, to, tokens, fee, nonce, sig, feeAccount);
    }
    function signedApproveAndCallHash(address signer, address spender, uint tokens, bytes _data, uint fee, uint nonce) public view returns (bytes32 hash) {
        return data.signedApproveAndCallHash(address(this), signer, spender, tokens, _data, fee, nonce);
    }
    function signedApproveAndCallCheck(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public constant returns (BTTSInterface.CheckResult result) {
        return data.signedApproveAndCallCheck(address(this), tokenOwner, spender, tokens, _data, fee, nonce, sig, feeAccount);
    }
    function signedApproveAndCall(address tokenOwner, address spender, uint tokens, bytes _data, uint fee, uint nonce, bytes sig, address feeAccount) public returns (bool success) {
        return data.signedApproveAndCall(address(this), tokenOwner, spender, tokens, _data, fee, nonce, sig, feeAccount);
    }
}