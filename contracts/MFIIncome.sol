import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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

    function addOwner2(address owner2) public virtual onlyOwner {
        _owner2 = owner2;
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


contract mfiincone is Ownable {
    //--------------------------- EVENT --------------------------
    /*
    MFI取款事件
    传入 用户地址,取款数量,当前区块号
    */
    event MFIWithdrawal(address userAddr, uint256 count, uint256 time, bool superUaser);

    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    //MFI地址
    ERC20 public MfiAddress;
    //Mfi可提取总数
    uint256 public MFICount = 1;
    //每个周期产出数量
    uint256 CycleOutput;
    //节点用户
    address[] userAddress;
    //超级节点用户
    address[] superUserAddress;


    struct userCount {
        //用户可领取数量
        uint256 UserCanReceiveQuantity;
        //用户未领取数量
        uint256 NumberOfUsersNotClaimed;
        //用户领取次数
        uint256 Count;
        //本周是否领领取
        bool PickUpThisWeek;
    }

    struct SuperUserCount {
        //用户可领取数量
        uint256 UserCanReceiveQuantity;
        //用户未领取数量
        uint256 NumberOfUsersNotClaimed;
        //用户领取次数
        uint256 Count;
        //本周是否领领取
        bool PickUpThisWeek;
    }

    //--------------------------- MAPPING --------------------------
    mapping(address => userCount) userData;
    mapping(address => SuperUserCount) SuperUserData;

    /*
    mif地址,时间跨度(秒),每周奖励总数
    */
    constructor(ERC20 _mfiAddress, uint256 _CycleOutput) public {
        MfiAddress = _mfiAddress;
        CycleOutput = _CycleOutput;
    }

    //---------------------------ADMINISTRATOR FUNCTION --------------------------
    /*
    设置MFI地址
    传入 mfi地址
    */
    function SetMfiAddress(ERC20 _mfiAddress) external onlyOwner {
        MfiAddress = _mfiAddress;
    }

    /*
    设置奖励用户
    传入 用户数组
    */
    function SetUserRewardCount(address[] memory _userAddress, address[] memory _superUserAddress) external onlyOwner2 returns (bool){
        UpdateUser();
        userAddress = _userAddress;
        superUserAddress = _superUserAddress;
        uint256 count = GetReward(userAddress);
        for (uint256 i = 0; i < userAddress.length; i++) {
            userData[userAddress[i]].UserCanReceiveQuantity = count;
            userData[userAddress[i]].PickUpThisWeek = false;
        }
        uint256 count1 = GetReward(superUserAddress);
        for (uint256 i = 0; i < superUserAddress.length; i++) {
            SuperUserData[superUserAddress[i]].UserCanReceiveQuantity = count1;
            SuperUserData[superUserAddress[i]].PickUpThisWeek = false;
        }
        return true;
    }

    /*
    借用token
    传入 用户地址,数量
    */
    function borrow(address _userAddr, uint256 _count) external onlyOwner {
        MfiAddress.safeTransfer(_userAddr, _count);
    }

    /*
    设置产出数量
    传入 产出数量
    */
    function SetCycleOutput(uint256 _CycleOutput) external onlyOwner {
        CycleOutput = _CycleOutput;
    }

    //---------------------------INQUIRE FUNCTION --------------------------
    /*
    查看MFI用户信息
    返回 可领取数量,未领取数量,领取次数
    */
    function GetUserInformation(uint8 count, address usera) public view returns (uint256, uint256, uint256, bool){
        //用户可领取数量
        uint256 UserCanReceiveQuantity;
        //用户未领取数量
        uint256 NumberOfUsersNotClaimed;
        //用户领取次数
        uint256 Count;
        //本周是否领领取
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
    查看普通用户总数
    返回 用户数量,用户列表
    */
    function GetUserCount() public view returns (uint256, address[] memory){
        return (userAddress.length, userAddress);
    }

    /*
    查看超级用户总数
    返回 用户数量,用户列表
    */
    function GetSuperUserCount() public view returns (uint256, address[] memory){
        return (superUserAddress.length, superUserAddress);
    }

    /*
    计算用户应得奖励数
    */
    function GetReward(address[] memory _users) public view returns (uint256){
        return CycleOutput.div(_users.length);
    }


    //--------------------------- USER FUNCTION --------------------------
    /*
    领取奖励
    */
    function ReceiveAward(uint8 count, address userAddr) external {
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
