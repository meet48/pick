// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @dev Meet token.
 */
interface IMeet is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

/**
 * @dev Pick token.
 */
interface IPick is IERC20 {
    function burnFrom(address account, uint256 amount) external;
    function mintTo(address to , uint256 amount) external;
}

/**
 * @dev reward pool.
 */
interface IRewardPool {
    function exchangeRecord(uint256 amount) external;
}

/**
 * @dev Meet exchange Pick.
 */
contract Exchange is Ownable , Pausable {
    AggregatorV3Interface public ethPriceFeed;
    address public meetPriceRole;
    uint256 internal _price;
    IMeet public Meet;
    IPick public Pick;
    IRewardPool public RewardPool;
    uint256 public meetBurnFee;

    event SetEthPriceFeed(address _address);
    event SetMeetPriceRole(address oldAddress , address newAddress);
    event SetMeetPrice(uint256 _price);
    event MintPick(address to , uint256 amount , uint256 meetAmount);
    event SetMeetBurnFee(uint256 oldFee , uint newFee);
    event SetRewardPool(address _address);

    constructor(address meet , address pick) {
        Meet = IMeet(meet);
        Pick = IPick(pick);
        meetPriceRole = msg.sender;
    }

        /**
     * Initializes critical contract parameters (callable only by contract owner)
     * @dev Performs safety checks and emits configuration events
     * @param _ethPriceFeed Chainlink price feed address for ETH/USD conversions
     * @param _meetPriceRole Address authorized for price adjustments
     * @param _rewardPool Contract handling reward distribution
     * @param _meetBurnFee Fee percentage (basis points) for token burns 
     */
    function init(
        address _ethPriceFeed,
        address _meetPriceRole,
        address _rewardPool,
        uint256 _meetBurnFee
    ) external onlyOwner {  // Restrict to contract owner
        // Validate and set ETH price feed (non-zero address check)
        require(_ethPriceFeed != address(0), "Exchange: zero address");
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);  // Chainlink interface binding
        emit SetEthPriceFeed(_ethPriceFeed);  // Log configuration change
    
        // Update price authority with dual-purpose emission pattern:
        // 1. Emits old value before update
        // 2. Updates storage variable via assignment in emit parameters
        require(_meetPriceRole != address(0), "Exchange: zero address");
        emit SetMeetPriceRole(meetPriceRole, meetPriceRole = _meetPriceRole);
    
        // Configure rewards pool contract 
        require(_rewardPool != address(0), "Exchange: zero address");
        RewardPool = IRewardPool(_rewardPool);  // Interface binding
        emit SetRewardPool(_rewardPool);
    
        // Validate fee percentage is 0 < fee < 100% (basis points format)
        require(_meetBurnFee > 0 && _meetBurnFee < 10000, "Exchange: Value out of range");
        // Emit before/after values using in-assignment update
        emit SetMeetBurnFee(meetBurnFee, meetBurnFee = _meetBurnFee);
    }   

    /**
     * @dev Set Chainlink eth price contract.
     */
    function setEthPriceFeed(address _address) external onlyOwner {
        require(_address != address(0) , "Exchange: zero address");
        ethPriceFeed = AggregatorV3Interface(_address);
        emit SetEthPriceFeed(_address);
    }

    /**
     * @dev Set address, can modify the meet token price.
     */
    function setMeetPriceRole(address _address) external onlyOwner {
        require(_address != address(0) , "Exchange: zero address");
        emit SetMeetPriceRole(meetPriceRole , meetPriceRole = _address);
    }

    /**
     * @dev Set meet token price , the unit is wei.
     */
    function setMeetPriceOfWEI(uint256 _meetPrice) external {
        require(msg.sender == meetPriceRole , "Exchange: Caller unauthorized");
        require(_meetPrice > 0 , "Exchange: zero");
        emit SetMeetPrice(_price = _meetPrice);
    }


    /**
     * @dev Set burn fee , 100% equal 10000.
     */
    function setMeetBurnFee(uint256 _fee) external onlyOwner {
        require(_fee > 0 && _fee < 10000 , "Exchange: Value out of range");
        emit SetMeetBurnFee(meetBurnFee , meetBurnFee = _fee);
    }


    /**
     * @dev Set reward pool.
     */
    function setRewardPool(address _address) external onlyOwner {
        require(_address != address(0) , "Exchange: zero address");
        RewardPool = IRewardPool(_address);
        emit SetRewardPool(_address);
    }


    /**
     * @dev pauses all mint.
     */
    function pause() public virtual onlyOwner {
        _pause();
    }


    /**
     * @dev unpauses all mint.
     */
    function unpause() public virtual onlyOwner {
        _unpause();
    }


    /**
     * @dev Returns eth price.
     */
    function getEthPrice() public view returns (int) {
        ( ,int price, , , ) = ethPriceFeed.latestRoundData();
        return price * (10 ** 10);
    }


    /**
     * @dev Returns meet token price.
     */
    function getMeetPrice() public view returns (int) {
        require(_price > 0 , "Exchange: price is zero");
        return (int(_price));
    }


    /**
     * @dev Returns the number of meet exchanged for pick.
     */
    function getPickAmount(uint256 meetAmount) public view returns (uint256) {
        uint256 ethPrice = uint256(getEthPrice());
        uint256 meetPrice = uint256(getMeetPrice());
        uint256 total = meetAmount * meetPrice * ethPrice / (10 ** 36);
        return total;
    }


    /**
     * @dev Returns the number of pick exchanged for meet.
     */
    function getMeetAmount(uint256 pickAmount) external view returns (uint256) {
        uint256 ethPrice = uint256(getEthPrice());
        uint256 meetPrice = uint256(getMeetPrice());    
        uint256 meetAmount = pickAmount * (10 ** 36) / ethPrice / meetPrice;
        return meetAmount;
    }


    /**
     * @dev meet exchange pick.
     */
    function mintPick(uint256 amount) external whenNotPaused {
        uint256 ethPrice = uint256(getEthPrice());
        uint256 meetPrice = uint256(getMeetPrice());

        require(address(RewardPool) != address(0) , "Exchange: meetReward zero address");
        require(ethPrice > 0 , "Exchange: the ETH price is incorrect");
        require(meetPrice > 0 , "Exchange: the meet price is not correct");
        require(address(Meet) != address(0) , "Exchange: Meet zero address");
        require(address(Pick) != address(0) , "Exchange: Pick zero address");
        
        uint256 burnAmount = amount * meetBurnFee / 10000;
        uint256 rewardPoolAmount = amount - burnAmount;

        uint256 pickAmount = getPickAmount(amount);
        require(pickAmount > 0 , "Exchange: Insufficient exchange amount");

        Meet.burnFrom(msg.sender , burnAmount);

        Meet.transferFrom(msg.sender , address(RewardPool) , rewardPoolAmount);
        RewardPool.exchangeRecord(rewardPoolAmount);

        Pick.mintTo(msg.sender , pickAmount);

        emit MintPick(msg.sender , pickAmount , amount);
    }



    
}
