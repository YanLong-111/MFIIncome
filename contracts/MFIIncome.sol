//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Initializable, ContextUpgradeable {
    address private _owner;
    address private _owner2;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    function __Ownable_init_unchained() internal initializer {
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

    /**
     * @dev Returns the address of the current owner2.
     */
    function owner2() public view virtual returns (address) {
        return _owner2;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "OW:f1");
        _;
    }
    modifier onlyOwner2() {
        require(_msgSender() == _owner2 || owner() == _msgSender(), "Ownable: caller is not the owner2");
        _;
    }

    function addOwner2(address owners2) public virtual onlyOwner {
        _owner2 = owners2;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "OW:f2");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}


contract MFIIncome is Ownable, PausableUpgradeable {
    //--------------------------- EVENT --------------------------
    /*
    MFI????????????
    ?????? ????????????,????????????,???????????????
    */
    event MFIWithdrawal(address userAddr, uint256 count, uint256 time, bool superUaser);

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //MFI??????
    IERC20 public MfiAddress;
    //Mfi???????????????
    uint256 public MFICount = 1;
    //????????????????????????
    uint256 CycleOutput;
    //????????????
    address[] userAddress;
    //??????????????????
    address[] superUserAddress;


    struct userCount {
        //?????????????????????
        uint256 UserCanReceiveQuantity;
        //?????????????????????
        uint256 NumberOfUsersNotClaimed;
        //??????????????????
        uint256 Count;
        //?????????????????????
        bool PickUpThisWeek;
    }

    struct SuperUserCount {
        //?????????????????????
        uint256 UserCanReceiveQuantity;
        //?????????????????????
        uint256 NumberOfUsersNotClaimed;
        //??????????????????
        uint256 Count;
        //?????????????????????
        bool PickUpThisWeek;
    }

    //--------------------------- MAPPING --------------------------
    mapping(address => userCount) userData;
    mapping(address => SuperUserCount) SuperUserData;

    /*
    mif??????,????????????(???),??????????????????
    *//*
    constructor(IERC20 _mfiAddress, uint256 _CycleOutput) public {
        MfiAddress = _mfiAddress;
        CycleOutput = _CycleOutput;
    }*/

    function initialize(
        IERC20 _mfiAddress,
        uint256 _CycleOutput)
    public initializer {
        __Ownable_init_unchained();
        __Pausable_init();
        MfiAddress = _mfiAddress;
        CycleOutput = _CycleOutput;
    }


    //---------------------------ADMINISTRATOR FUNCTION --------------------------
    /*
    ??????MFI??????
    ?????? mfi??????
    */
    function SetMfiAddress(IERC20 _mfiAddress) external onlyOwner {
        super._pause();
        MfiAddress = _mfiAddress;
        super._unpause();}

    /*
    ??????????????????
    ?????? ????????????
    */
    function SetUserRewardCount(
        uint88 _count,
        uint88 _superCount,
        address[] memory _userAddress,
        address[] memory _superUserAddress
    ) external onlyOwner2 returns (bool){
        super._pause();
        UpdateUser();
        userAddress = _userAddress;
        superUserAddress = _superUserAddress;
        uint256 count = GetReward(_count);
        for (uint256 i = 0; i < userAddress.length; i++) {
            userData[userAddress[i]].UserCanReceiveQuantity = count;
            userData[userAddress[i]].PickUpThisWeek = false;
        }
        uint256 count1 = GetReward(_superCount);
        for (uint256 i = 0; i < superUserAddress.length; i++) {
            SuperUserData[superUserAddress[i]].UserCanReceiveQuantity = count1;
            SuperUserData[superUserAddress[i]].PickUpThisWeek = false;
        }
        super._unpause();
        return true;
    }

    /**
    * @dev ??????????????????
    * @param    _userAddress    ??????????????????
    * @param    _superUserAddress   ??????????????????
    * @return   bool    ??????
    */
    function AddUserReward(
        uint88 _count,
        uint88 _superCount,
        address[] memory _userAddress,
        address[] memory _superUserAddress
    ) external onlyOwner2 returns (bool){
        super._pause();
        require(
            (userAddress.length < _count && _userAddress.length < _count)
            &&
            (superUserAddress.length < _superCount && _superUserAddress.length < _superCount)
        ,"Check the length of the existing array"
        );

        require(
            (userAddress.length + _userAddress.length <= _count)
            &&
            (superUserAddress.length + _superUserAddress.length <= _superCount)
        ,"Check the sum length"
        );
        uint256 count = GetReward(_count);
        for (uint256 i = 0; i < _userAddress.length; i++) {
            if (userData[_userAddress[i]].UserCanReceiveQuantity == 0) {
                userAddress.push(_userAddress[i]);
                userData[userAddress[userAddress.length - 1]].UserCanReceiveQuantity = count;
                userData[userAddress[userAddress.length - 1]].PickUpThisWeek = false;
            }
        }
        uint256 count1 = GetReward(_superCount);
        for (uint256 i = 0; i < _superUserAddress.length; i++) {
            if (SuperUserData[_superUserAddress[i]].UserCanReceiveQuantity == 0) {
                superUserAddress.push(_superUserAddress[i]);
                SuperUserData[superUserAddress[superUserAddress.length - 1]].UserCanReceiveQuantity = count1;
                SuperUserData[superUserAddress[superUserAddress.length - 1]].PickUpThisWeek = false;
            }
        }
        super._unpause();
        return true;
    }

    /*
    ??????token
    ?????? ????????????,??????
    */
    function borrow(address _userAddr, uint256 _count) external onlyOwner {
        MfiAddress.safeTransfer(_userAddr, _count);
    }

    /*
    ??????????????????
    ?????? ????????????
    */
    function SetCycleOutput(uint256 _CycleOutput) external onlyOwner {
        super._pause();
        CycleOutput = _CycleOutput;
        super._unpause();

    }

    //---------------------------INQUIRE FUNCTION --------------------------
    /*
    ??????MFI????????????
    ?????? ???????????????,???????????????,????????????
    */
    function GetUserInformation(uint8 count, address usera) public view returns (uint256, uint256, uint256, bool){
        //?????????????????????
        uint256 UserCanReceiveQuantity;
        //?????????????????????
        uint256 NumberOfUsersNotClaimed;
        //??????????????????
        uint256 Count;
        //?????????????????????
        bool PickUpThisWeek;
        if (count == 1) {
            UserCanReceiveQuantity = userData[usera].UserCanReceiveQuantity;
            NumberOfUsersNotClaimed = userData[usera].NumberOfUsersNotClaimed;
            Count = userData[usera].Count;
            PickUpThisWeek = userData[usera].PickUpThisWeek;
            return (UserCanReceiveQuantity, NumberOfUsersNotClaimed, Count, PickUpThisWeek);
        } else {
            UserCanReceiveQuantity = SuperUserData[usera].UserCanReceiveQuantity;
            NumberOfUsersNotClaimed = SuperUserData[usera].NumberOfUsersNotClaimed;
            Count = SuperUserData[usera].Count;
            PickUpThisWeek = SuperUserData[usera].PickUpThisWeek;
            return (UserCanReceiveQuantity, NumberOfUsersNotClaimed, Count, PickUpThisWeek);
        }
    }

    /*
    ????????????????????????
    ?????? ????????????,????????????
    */
    function GetUserCount() public view returns (uint256, address[] memory){
        return (userAddress.length, userAddress);
    }

    /*
    ????????????????????????
    ?????? ????????????,????????????
    */
    function GetSuperUserCount() public view returns (uint256, address[] memory){
        return (superUserAddress.length, superUserAddress);
    }

    /*
    ???????????????????????????
    */
    function GetReward(uint88 _count) public view returns (uint256){
        return CycleOutput.div(_count);
    }


    //--------------------------- USER FUNCTION --------------------------
    /*
    ????????????
    */
    function ReceiveAward(uint8 count, address userAddr) external whenNotPaused {
        userCount storage userdata = userData[userAddr];
        SuperUserCount storage superUserData = SuperUserData[userAddr];
        uint256 UserCanReceiveQuantity;
        uint256 NumberOfUsersNotClaimed;
        if (count == 1) {
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
        if (count == 1) {
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
        MfiAddress.safeTransfer(userAddr, RewardCount);
    }

    function UpdateUser() private {
        for (uint256 i = 0; i < userAddress.length; i++) {
            judgment(userAddress[i]);
        }
        for (uint256 i = 0; i < superUserAddress.length; i++) {
            superJudgment(superUserAddress[i]);
        }
    }

    function judgment(address useradd) private {
        if (userData[useradd].PickUpThisWeek == false) {
            userData[useradd].NumberOfUsersNotClaimed += userData[useradd].UserCanReceiveQuantity;
            userData[useradd].UserCanReceiveQuantity = 0;
        }
    }

    function superJudgment(address useradd) private {
        if (SuperUserData[useradd].PickUpThisWeek == false) {
            SuperUserData[useradd].NumberOfUsersNotClaimed += SuperUserData[useradd].UserCanReceiveQuantity;
            SuperUserData[useradd].UserCanReceiveQuantity = 0;
        }
    }
}

