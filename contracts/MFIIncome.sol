//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract Ownable is Context {
    address private _owner;
    address private _owner2;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    function owner2() public view virtual returns (address) {
        return _owner2;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOwner2() {
        require(_msgSender() == _owner2 || owner() == _msgSender(), "Ownable: caller is not the owner2");
        _;
    }
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function addOwner2(address owners2) public virtual onlyOwner {
        _owner2 = owners2;
    }
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract MFIIncome is Ownable, Pausable {
    //--------------------------- EVENT --------------------------



    /**
    * @dev MFI取款事件
    */
    event MFIWithdrawal(address userAddr, uint256 count, uint256 time, bool superUaser);

    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    //MFI地址
    ERC20 public MfiAddress;
    //Mfi可提取总数
    uint88 public MFICount;
    //节点用户
    address[] public userAddress;
    //超级节点用户
    address[] public superUserAddress;

    //节点用户奖励数组
    uint88[] public  UserRewards;
    //超级节点用户奖励数组
    uint88[] public superUserRewards;

    struct userCount {
        //用户可领取数量
        uint88 UserCanReceiveQuantity;
        //用户未领取数量
        uint88 NumberOfUsersNotClaimed;
        //用户领取次数
        uint88 Count;
        //本周是否领领取
        bool PickUpThisWeek;
    }

    struct SuperUserCount {
        //用户可领取数量
        uint88 UserCanReceiveQuantity;
        //用户未领取数量
        uint88 NumberOfUsersNotClaimed;
        //用户领取次数
        uint88 Count;
        //本周是否领领取
        bool PickUpThisWeek;
    }

    //--------------------------- MAPPING --------------------------
    mapping(address => userCount) public userData;
    mapping(address => SuperUserCount) public SuperUserData;


    /**
    * @dev  mif地址
    */
    constructor(ERC20 _mfiAddress)  {
        MfiAddress = _mfiAddress;
    }

    //---------------------------ADMINISTRATOR FUNCTION --------------------------
    /**
    * @dev  设置MFI地址
    * @param    _mfiAddress     mfi地址
    */
    function SetMfiAddress(ERC20 _mfiAddress) external onlyOwner {
        super._pause();
        MfiAddress = _mfiAddress;
        super._unpause();
    }

    /**
    * @dev 设置奖励用户
    * @param    _userAddress    普通用户数组
    * @param    _superUserAddress   超级用户数组
    * @return   bool    成功
    */
    function SetUserRewardCount(address[] memory _userAddress, address[] memory _superUserAddress) external onlyOwner2 returns (bool){
        super._pause();
        UpdateUser();
        userAddress = _userAddress;
        superUserAddress = _superUserAddress;
        for (uint8 i = 0; i < userAddress.length; i++) {
            userData[userAddress[i]].UserCanReceiveQuantity = UserRewards[i];
            userData[userAddress[i]].PickUpThisWeek = false;
        }
        for (uint8 i = 0; i < superUserAddress.length; i++) {
            SuperUserData[superUserAddress[i]].UserCanReceiveQuantity = superUserRewards[i];
            SuperUserData[superUserAddress[i]].PickUpThisWeek = false;
        }
        super._unpause();
        return true;
    }

    /**
    * @dev 借用token
    * @param    _userAddr    用户地址
    * @param    _count   数量
    */
    function borrow(address _userAddr, uint160 _count) external onlyOwner {
        MfiAddress.safeTransfer(_userAddr, _count);
    }

    /**
    * @dev  设置奖励数组
    * @param    _userDataArray  普通用户奖励数组
    * @param    _superUserDataArray 超级用户奖励数组
    */
    function SetUpTheRewardArray(uint88[] memory _userDataArray, uint88[] memory _superUserDataArray) external onlyOwner {
        super._pause();
        UserRewards = _userDataArray;
        superUserRewards = _superUserDataArray;
        super._unpause();
    }
    //---------------------------INQUIRE FUNCTION --------------------------
    /**
    * @dev  查看MFI用户信息
    * @param    _count  1为普通用户，其他为超级用户
    * @param    _users  用户地址
    * @return   可领取数量,未领取数量,领取次数
    */
    function GetUserInformation(uint8 _count, address _users) public view returns (uint88, uint88, uint88, bool){
        //用户可领取数量
        uint88 UserCanReceiveQuantity;
        //用户未领取数量
        uint88 NumberOfUsersNotClaimed;
        //用户领取次数
        uint88 Count;
        //本周是否领领取
        bool PickUpThisWeek;
        if (_count == 1) {
            UserCanReceiveQuantity = userData[_users].UserCanReceiveQuantity;
            NumberOfUsersNotClaimed = userData[_users].NumberOfUsersNotClaimed;
            Count = userData[_users].Count;
            PickUpThisWeek = userData[_users].PickUpThisWeek;
            return (UserCanReceiveQuantity, NumberOfUsersNotClaimed, Count, PickUpThisWeek);
        } else {
            UserCanReceiveQuantity = SuperUserData[_users].UserCanReceiveQuantity;
            NumberOfUsersNotClaimed = SuperUserData[_users].NumberOfUsersNotClaimed;
            Count = SuperUserData[_users].Count;
            PickUpThisWeek = SuperUserData[_users].PickUpThisWeek;
            return (UserCanReceiveQuantity, NumberOfUsersNotClaimed, Count, PickUpThisWeek);
        }
    }

    /**
    * @dev  查看普通用户总数
    * @return   用户数量,用户列表
    */
    function GetUserCount() public view returns (uint8, address[] memory){
        return (uint8(userAddress.length), userAddress);
    }


    /**
    * @dev  查看超级用户总数
    * @return   用户数量,用户列表
    */
    function GetSuperUserCount() public view returns (uint8, address[] memory){
        return (uint8(superUserAddress.length), superUserAddress);
    }



    //--------------------------- USER FUNCTION --------------------------
    /**
    * @dev  领取奖励
    * @param    _count  1为普通用户，其他为超级用户
    * @param    _userAddr  用户地址
    */
    function ReceiveAward(uint8 _count, address _userAddr) external whenNotPaused {
        userCount storage userdata = userData[_userAddr];
        SuperUserCount storage superUserData = SuperUserData[_userAddr];
        uint256 UserCanReceiveQuantity;
        uint256 NumberOfUsersNotClaimed;
        if (_count == 1) {
            UserCanReceiveQuantity = userdata.UserCanReceiveQuantity;
            NumberOfUsersNotClaimed = userdata.NumberOfUsersNotClaimed;
        } else {
            UserCanReceiveQuantity = superUserData.UserCanReceiveQuantity;
            NumberOfUsersNotClaimed = superUserData.NumberOfUsersNotClaimed;
        }
        require(UserCanReceiveQuantity > 1000 || NumberOfUsersNotClaimed > 1000, "Without your reward:(");
        uint256 RewardCount;
        if (NumberOfUsersNotClaimed > 1000 && UserCanReceiveQuantity < 1000) {
            RewardCount = NumberOfUsersNotClaimed;
        }
        if (UserCanReceiveQuantity > 1000 && NumberOfUsersNotClaimed < 1000) {
            RewardCount = UserCanReceiveQuantity;
        }
        if (UserCanReceiveQuantity > 1000 && NumberOfUsersNotClaimed > 1000) {
            RewardCount = UserCanReceiveQuantity.add(NumberOfUsersNotClaimed);
        }
        if (_count == 1) {
            userdata.UserCanReceiveQuantity = 0;
            userdata.NumberOfUsersNotClaimed = 0;
            userdata.Count++;
            userdata.PickUpThisWeek = true;
        } else {
            superUserData.UserCanReceiveQuantity = 0;
            superUserData.NumberOfUsersNotClaimed = 0;
            superUserData.Count++;
            superUserData.PickUpThisWeek = true;
        }
        MfiAddress.safeTransfer(_userAddr, RewardCount);
    }

    /**
    * @dev   更新用户
    */
    function UpdateUser() private {
        for (uint256 i = 0; i < userAddress.length; i++) {
            judgment(userAddress[i]);
        }
        for (uint256 i = 0; i < superUserAddress.length; i++) {
            superJudgment(superUserAddress[i]);
        }
    }


    /**
    * @dev   普通用户判断
    * @param  _useradd  用户地址
    */
    function judgment(address _useradd) private {
        if (userData[_useradd].PickUpThisWeek == false) {
            userData[_useradd].NumberOfUsersNotClaimed += userData[_useradd].UserCanReceiveQuantity;
            userData[_useradd].UserCanReceiveQuantity = 0;
        }
    }

    /**
    * @dev   超级用户判断
    * @param  _useradd  用户地址
    */
    function superJudgment(address _useradd) private {
        if (SuperUserData[_useradd].PickUpThisWeek == false) {
            SuperUserData[_useradd].NumberOfUsersNotClaimed += SuperUserData[_useradd].UserCanReceiveQuantity;
            SuperUserData[_useradd].UserCanReceiveQuantity = 0;
        }
    }
}

