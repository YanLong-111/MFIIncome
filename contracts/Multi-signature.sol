//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface mfiincone {
    function SetUserRewardCount(address[] calldata _userAddress, address[] calldata _superUserAddress) external returns (bool);
}

contract MultiSig {

    // ============ Events ============

    // ============ Constants ============

    uint256 constant public MAX_OWNER_COUNT = 50;
    address constant ADDRESS_ZERO = address(0x0);
    address destination;

    // ============ Storage ============

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;
    uint256 public ctionId;
    bool public whetherSucceed = false;

    // ============ Structs ============

    struct Transaction {
        address[] userAddress;
        address[] superUserAddress;
        bool executed;
    }

    // ============ Modifiers ============
    modifier onlyWallet() {
        /* solium-disable-next-line error-reason */
        require(msg.sender == address(this));
        _;
    }
    modifier ownerDoesNotExist(address owner) {
        /* solium-disable-next-line error-reason */
        require(!isOwner[owner]);
        _;
    }
    modifier ownerExists(address owner) {
        /* solium-disable-next-line error-reason */
        require(isOwner[owner], "ownerExists!!!!!!!!!!!");
        _;
    }
    modifier transactionExists(uint256 transactionId) {
        /* solium-disable-next-line error-reason */
        require(destination != ADDRESS_ZERO, "transactionExists@@@@@@@@@@@@");
        _;
    }
    modifier confirmed(uint256 transactionId, address owner) {
        /* solium-disable-next-line error-reason */
        require(confirmations[transactionId][owner]);
        _;
    }
    modifier notConfirmed(uint256 transactionId, address owner) {
        /* solium-disable-next-line error-reason */
        require(!confirmations[transactionId][owner], "notConfirmed#######");
        _;
    }
    modifier notExecuted(uint256 transactionId) {
        /* solium-disable-next-line error-reason */
        require(!transactions[transactionId].executed);
        _;
    }
    modifier notNull(address _address) {
        /* solium-disable-next-line error-reason */
        require(_address != ADDRESS_ZERO);
        _;
    }
    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        /* solium-disable-next-line error-reason */
        require(
            ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0
        );
        _;
    }

    // ============ Constructor ============


    /**
     * ???????????????????????????????????????????????????????????????
     * @param  _owners    ?????????????????????(??????)
     * @param  _required  ?????????????????????
     */
    constructor(address[] memory _owners, uint256 _required, address mfidestination)  validRequirement(_owners.length, _required){
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != ADDRESS_ZERO);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        destination = mfidestination;
    }
    /**
     *????????????????????????????????????
     *@param  _userAddress  ??????????????????
     *@param  _superUserAddress ??????????????????
     */
    function submitTransaction(address[] memory _userAddress, address[] memory _superUserAddress) public returns (uint256){
        uint256 transactionId = addTransaction(_userAddress, _superUserAddress);
        ctionId = transactionId;
        confirmTransaction(transactionId);
        whetherSucceed = true;
        return transactionId;
    }


    /**
     * ???????????????????????????.
     * @param  transactionId  Transaction ID.???????????????
     */
    function confirmTransaction(uint256 transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;

        executeTransaction(transactionId);
    }

    /**
     * ???????????????????????????????????????
     * @param  transactionId  ???????????????
     */
    function executeTransaction(uint256 transactionId) private ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {

        if (isConfirmed(transactionId)) {
            for (uint256 i = 0; i < owners.length; i++) {
                confirmations[transactionId][owners[i]] = false;
                whetherSucceed = false;
            }
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            mfiincone(destination).SetUserRewardCount(txn.userAddress, txn.superUserAddress);

        }
    }

    // ============ Getter Functions ============

    /**
     * ??????????????????????????????
     *
     * @param  transactionId  Transaction ID.????????????
     * @return                Confirmation status.???????????????
     */
    function isConfirmed(uint256 transactionId) public view returns (bool){
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
        return false;
    }

    /**
     * ????????????
     * @param  _userAddress  ??????????????????
     * @param  _superUserAddress ??????????????????
     * @return  transactionId  ??????id
     */
    function addTransaction(address[] memory _userAddress, address[] memory _superUserAddress) internal notNull(destination) returns (uint256){
        uint256 transactionId = 1;
        transactions[transactionId] = Transaction({
        userAddress : _userAddress,
        superUserAddress : _superUserAddress,
        executed : false
        });
        return transactionId;
    }

    /**
    * ??????????????????
    * @return  whetherSucceed  ??????????????????
    */
    function GetWhetherSucceed() public view returns (bool){
        return whetherSucceed;
    }
}
