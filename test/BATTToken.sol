pragma solidity ^0.4.17;

// ----------------------------------------------------------------------------
// BATTT 'BokkyPooBah's Assisted Token Transfer Token' token contract
//
// Deployed to : 
// Symbol      : BATTT
// Name        : BokkyPooBah's Assisted Token Transfer Token
// Total supply: 10 million
// Decimals    : 18
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
    event OwnershipTransferred(address indexed _from, address indexed _to);
}


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


// ----------------------------------------------------------------------------
// Safe maths, borrowed from OpenZeppelin
// ----------------------------------------------------------------------------
library SafeMath {

    // ------------------------------------------------------------------------
    // Add a number to another number, checking for overflows
    // ------------------------------------------------------------------------
    function add(uint a, uint b) public pure returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
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
contract BATTToken is ERC20Interface, Owned {
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
    bool public transferable = false;
    bool public mintable = true;

    // ------------------------------------------------------------------------
    // Data for signing and ecrecover
    // ------------------------------------------------------------------------
    bytes public constant signingPrefix = "\x19Ethereum Signed Message:\n32";

    // ------------------------------------------------------------------------
    // signedTransfer(...) function signature
    // web3.sha3("signedTransfer(address,address,address,uint256,uint256,uint256,uint8,bytes32,bytes32)").substring(0,10)
    // => "0x4a07bd1f"
    // ------------------------------------------------------------------------
    bytes4 public constant signedTransferSig = "\x4a\x07\xbd\x1f";


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
    function BATTToken(string _symbol, string _name, uint8 _decimals, 
        uint _initialSupply) public 
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
    }


    // ------------------------------------------------------------------------
    // Enable transfers
    // ------------------------------------------------------------------------
    function enableTransfers() public onlyOwner {
        require(!transferable);
        transferable = true;
    }


    // ------------------------------------------------------------------------
    // Disable minting
    // ------------------------------------------------------------------------
    function disableMinting() public onlyOwner {
        require(mintable);
        mintable = false;
    }


    // ------------------------------------------------------------------------
    // Get the account balance of another account with address _owner
    // ------------------------------------------------------------------------
    function balanceOf(address owner) public constant returns (uint balance) {
        return balances[owner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from owner's account to another account
    // - Account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(transferable);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Allow _spender to withdraw from your account, multiple times, up to the
    // _value amount. If this function is called again it overwrites the
    // current allowance with _value.
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens)
        public returns (bool success) 
    {
        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((tokens == 0) || (allowed[msg.sender][spender] == 0));

        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Spender of tokens transfer an amount of tokens from the token owner's
    // balance to another account. The owner of the tokens must already
    // have approve(...)-d this transfer
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens)
        public returns (bool success)
    {
        require(transferable);
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
    // signedTransfer helper
    //
    // Function to generate the hash used to create the signed transfer message
    // ------------------------------------------------------------------------
    function signedTransferHash(address tokenContractAddress,
        address from, address to, uint tokens, uint fee,
        uint nonce)
        public pure returns (bytes32 hash) 
    {
        hash = keccak256(signedTransferSig, tokenContractAddress,
            from, to, tokens, fee, nonce);
    }


    // ------------------------------------------------------------------------
    // signedTransfer helper
    //
    // Check whether a transfer can be executed on behalf of the user who
    // signed the transfer message
    // ------------------------------------------------------------------------
    function signedTransferCheck(address tokenContractAddress,
        address from, address to, uint tokens, uint fee,
        uint nonce, uint8 v, bytes32 r, bytes32 s)
        public constant returns (bool success) 
    {
        if (tokenContractAddress != address(this)) return false;
        if (!transferable) return false;
        bytes32 hash = signedTransferHash(tokenContractAddress,
            from, to, tokens, fee, nonce);
        bytes32 prefixedHash = keccak256(signingPrefix, hash);
        address signer = ecrecover(prefixedHash, v, r, s);

        if (from != signer) return false;
        if (executed[from][hash]) return false;
        if (balances[from] < (tokens + fee)) return false;
        return true;
    }


    // ------------------------------------------------------------------------
    // signedTransfer
    //
    // Execute a transfer on behalf of the user who signed the transfer 
    // message
    // ------------------------------------------------------------------------
    function signedTransfer(address tokenContractAddress,
        address from, address to, uint tokens, uint fee,
        uint nonce, uint8 v, bytes32 r, bytes32 s)
        public returns (bool success) 
    {
        // Check we are executing with the right contract
        // and tokens are transferable
        require(tokenContractAddress == address(this));
        require(transferable);

        // Check the user who signed the message matches
        // the transfer instructions
        bytes32 hash = signedTransferHash(tokenContractAddress,
            from, to, tokens, fee, nonce);
        bytes32 prefixedHash = keccak256(signingPrefix, hash);
        address signer = ecrecover(prefixedHash, v, r, s);
        require(from == signer);

        // Check we have not already executed this transfer
        require(!executed[from][hash]);
        executed[from][hash] = true;

        // Move the tokens and fees
        balances[from] = balances[from].sub(tokens);
        balances[from] = balances[from].sub(fee);
        balances[to] = balances[to].add(tokens);
        balances[msg.sender] = balances[msg.sender].add(fee);

        // Log transfers
        Transfer(from, to, tokens);
        Transfer(from, msg.sender, fee);
        SignedTransfer(msg.sender, from, from, to, tokens, fee, nonce, v, r, s);
        return true;
    }
    event SignedTransfer(address indexed executor, address spender, 
      address indexed from, address indexed to,
      uint tokens, uint fee, uint nonce, uint8 v, bytes32 r, bytes32 s);



    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens)
      public onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}