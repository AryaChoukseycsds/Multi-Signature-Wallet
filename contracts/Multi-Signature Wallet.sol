// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSignatureWallet {
    
    event Deposit(address indexed sender, uint256 amount);
    event TransactionSubmitted(uint256 indexed txId, address indexed to, uint256 value);
    event TransactionConfirmed(uint256 indexed txId, address indexed owner);
    event TransactionExecuted(uint256 indexed txId);

    address public owner1;
    address public owner2;
    address public owner3;
    uint256 public requiredConfirmations = 2;
    uint256 public transactionCount;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 confirmations;
        mapping(address => bool) isConfirmed;
    }

    mapping(uint256 => Transaction) public transactions;

    modifier onlyOwner() {
        require(
            msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3,
            "Not an owner"
        );
        _;
    }

    modifier txExists(uint256 _txId) {
        require(_txId < transactionCount, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }

    modifier notConfirmed(uint256 _txId) {
        require(!transactions[_txId].isConfirmed[msg.sender], "Already confirmed");
        _;
    }

    constructor() {
        owner1 = msg.sender;
        owner2 = msg.sender;
        owner3 = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address _to, uint256 _value) external onlyOwner {
        require(_to != address(0), "Invalid destination");
        require(_value > 0, "Value must be greater than 0");
        require(address(this).balance >= _value, "Insufficient balance");

        uint256 txId = transactionCount;
        
        Transaction storage newTx = transactions[txId];
        newTx.to = _to;
        newTx.value = _value;
        newTx.executed = false;
        newTx.confirmations = 0;

        transactionCount++;
        
        emit TransactionSubmitted(txId, _to, _value);
    }

    function confirmTransaction(uint256 _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
        notConfirmed(_txId) 
    {
        Transaction storage transaction = transactions[_txId];
        transaction.isConfirmed[msg.sender] = true;
        transaction.confirmations++;

        emit TransactionConfirmed(_txId, msg.sender);

        if (transaction.confirmations >= requiredConfirmations) {
            executeTransaction(_txId);
        }
    }

    function executeTransaction(uint256 _txId) 
        public 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        Transaction storage transaction = transactions[_txId];
        require(transaction.confirmations >= requiredConfirmations, "Not enough confirmations");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success, "Transaction failed");

        emit TransactionExecuted(_txId);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTransaction(uint256 _txId) 
        external 
        view 
        returns (address to, uint256 value, bool executed, uint256 confirmations) 
    {
        Transaction storage transaction = transactions[_txId];
        return (transaction.to, transaction.value, transaction.executed, transaction.confirmations);
    }

    function getOwners() external view returns (address, address, address) {
        return (owner1, owner2, owner3);
    }

    /// 🔹 New Function Added
    function getConfirmations(uint256 _txId)
        external
        view
        txExists(_txId)
        returns (address[] memory confirmedOwners)
    {
        Transaction storage transaction = transactions[_txId];
        address ;
        uint256 count = 0;

        if (transaction.isConfirmed[owner1]) {
            temp[count] = owner1;
            count++;
        }
        if (transaction.isConfirmed[owner2]) {
            temp[count] = owner2;
            count++;
        }
        if (transaction.isConfirmed[owner3]) {
            temp[count] = owner3;
            count++;
        }

        confirmedOwners = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            confirmedOwners[i] = temp[i];
        }
    }
}
// Added one function Suggested by ChatGpt
