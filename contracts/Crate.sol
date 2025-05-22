// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { IEntropyConsumer } from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import { IEntropy } from "@pythnetwork/entropy-sdk-solidity/IEntropy.sol";


interface IBerachainRewardVaultFactory {
    function createRewardVault(address vaultToken) external returns (address);
}

interface IRewardVault {
    function stake(uint256 amount) external;
    function getReward(address account, address recipient) external returns (uint256);
}

interface IBGT {
    function unboostedBalanceOf(address account) external view returns (uint256);
    function redeem(address receiver, uint256 amount) external;
}

interface IWBERA {
    function deposit() external payable;
}

contract VaultToken is ERC20, Ownable {

    constructor() ERC20("HoneyCrates", "HoneyCrates") {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyOwner {
        _burn(from, amount);
    }
}

contract Crate is ReentrancyGuard, Ownable, IEntropyConsumer {
    using SafeERC20 for IERC20;

    /*----------  CONSTANTS  --------------------------------------------*/

    uint256 public constant DEPOSIT_AMOUNT = 1 ether;
    uint256 public constant BASIS_POINTS = 10_000; // 100% = 10,000
    address public constant BGT = 0x656b95E550C07a9ffe548bd4085c72418Ceb1dba;

    /*----------  STATE VARIABLES  --------------------------------------*/

    IEntropy public entropy;

    address public immutable rewardToken;
    address public immutable vaultToken;
    address public immutable rewardVault;

    address public treasury;
    address public developer;
    address public incentives;

    bool public activeIncentives = false;
    bool public initialized = false;

    uint256 public maxIndex = 100;
    uint256 public price = 0.01 ether;

    mapping(uint256 => uint256) public index_RewardRate;
    mapping(uint64 => address) public sequence_Account;

    /*----------  ERRORS ------------------------------------------------*/

    error Crate__InvalidZeroAddress();
    error Crate__NotInitialized();
    error Crate__InsufficientPayment();
    error Crate__InsufficientFee();
    error Crate__InvalidSequence();
    error Crate__AlreadyInitialized();
    error Crate__InvalidRewardRate();
    error Crate__InvalidArrayLength();
    error Crate__InvalidRange();
    error Crate__NotDeveloper();

    /*----------  EVENTS ------------------------------------------------*/

    event Crate__Initialized();
    event Crate__PriceSet(uint256 price);
    event Crate__IndexSet(uint256 index, uint256 rate);
    event Crate__MaxIndexSet(uint256 maxIndex);
    event Crate__TreasurySet(address treasury);
    event Crate__DeveloperSet(address developer);
    event Crate__IncentivesSet(address incentives);
    event Crate__Distributed(uint256 developerAmount, uint256 treasuryAmount, uint256 incentivesAmount);
    event Crate__OpenRequest(uint64 sequenceNumber, address player);
    event Crate__OpenResult(address indexed player, uint64 sequenceNumber, uint256 randomValue, uint256 rewardPercent, uint256 reward);


    /*----------  MODIFIERS  --------------------------------------------*/

    /*----------  FUNCTIONS  --------------------------------------------*/

    constructor(
        address _rewardToken,
        address _treasury,
        address _developer,
        address _incentives,
        address _vaultFactory,
        address _entropy
    ) {
        rewardToken = _rewardToken;
        treasury = _treasury;
        developer = _developer;
        incentives = _incentives;
        entropy = IEntropy(_entropy);
        vaultToken = address(new VaultToken());
        rewardVault = IBerachainRewardVaultFactory(_vaultFactory).createRewardVault(address(vaultToken));
    }

    receive() external payable {}

    function distribute() external nonReentrant {
        uint256 balance = address(this).balance;
        uint256 incentivesAmount = balance * 80 / 100;
        uint256 developerAmount = balance * 10 / 100;
        uint256 treasuryAmount = balance - incentivesAmount - developerAmount;

        IWBERA(rewardToken).deposit{value: balance}();
        
        IERC20(rewardToken).safeTransfer(developer, developerAmount);
        IERC20(rewardToken).safeTransfer(treasury, treasuryAmount);
        IERC20(rewardToken).safeTransfer(incentives, incentivesAmount);

        emit Crate__Distributed(developerAmount, treasuryAmount, incentivesAmount);
    }

    function initialize() external {
        if (initialized) revert Crate__AlreadyInitialized();
        initialized = true;

        VaultToken(vaultToken).mint(address(this), DEPOSIT_AMOUNT);
        IERC20(vaultToken).safeApprove(rewardVault, 0);
        IERC20(vaultToken).safeApprove(rewardVault, DEPOSIT_AMOUNT);
        IRewardVault(rewardVault).stake(DEPOSIT_AMOUNT);

        emit Crate__Initialized();
    }

    function open(address account, bytes32 userRandomNumber) external payable nonReentrant {
        if (!initialized) revert Crate__NotInitialized();
        if (msg.value < price) revert Crate__InsufficientPayment();

        if (address(entropy) != address(0)) {
            address entropyProvider = entropy.getDefaultProvider();
            uint256 fee = entropy.getFee(entropyProvider);
            if (msg.value < price + fee) revert Crate__InsufficientFee();
            uint64 sequenceNumber = entropy.requestWithCallback{value: fee}(entropyProvider, userRandomNumber);
            sequence_Account[sequenceNumber] = account;
            emit Crate__OpenRequest(sequenceNumber, account);
        } else {
            userRandomNumber = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender));
            mockCallback(account, userRandomNumber);
            emit Crate__OpenRequest(0, account);
        }

        uint256 bgtReward = IRewardVault(rewardVault).getReward(address(this), address(this));
        if (bgtReward > 0) {
            IBGT(BGT).redeem(address(this), bgtReward);
            IWBERA(rewardToken).deposit{value: bgtReward}();
        }
    }

    /*----------  RESTRICTED FUNCTIONS  ---------------------------------*/

    function entropyCallback(
        uint64 sequenceNumber,
        address,
        bytes32 randomNumber
    ) internal override {
        address account = sequence_Account[sequenceNumber];
        if (account == address(0)) revert Crate__InvalidSequence();

        uint256 randomValue = uint256(randomNumber) % maxIndex;
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 rewardPercent = index_RewardRate[randomValue];
        uint256 reward = (balance * rewardPercent) / BASIS_POINTS;

        if (reward > 0) {
            IERC20(rewardToken).safeTransfer(account, reward);
        }

        delete sequence_Account[sequenceNumber];
        emit Crate__OpenResult(account, sequenceNumber, randomValue, rewardPercent, reward);
    }

    function mockCallback(address account, bytes32 randomValue) internal {

        uint256 randomIndex = uint256(randomValue) % maxIndex;
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        uint256 rewardPercent = index_RewardRate[randomIndex];
        uint256 reward = (balance * rewardPercent) / BASIS_POINTS;

        if (reward > 0) {
            IERC20(rewardToken).safeTransfer(account, reward);
        }

        emit Crate__OpenResult(account, 0, randomIndex, rewardPercent, reward);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
        emit Crate__PriceSet(price);
    }

    function setIndex(uint256 index, uint256 rate) external onlyOwner {
        if (rate >= BASIS_POINTS) revert Crate__InvalidRewardRate();
        index_RewardRate[index] = rate;
        emit Crate__IndexSet(index, rate);
    }

    function setIndexes(uint256[] calldata indexes, uint256[] calldata rates) external onlyOwner {
        if (indexes.length != rates.length) revert Crate__InvalidArrayLength();
        for (uint256 i = 0; i < indexes.length; i++) {
            if (rates[i] > BASIS_POINTS) revert Crate__InvalidRewardRate();
            index_RewardRate[indexes[i]] = rates[i];
            emit Crate__IndexSet(indexes[i], rates[i]);
        }
    }

    function setIndexRange(uint256 startIndex, uint256 endIndex, uint256 rate) external onlyOwner {
        if (startIndex > endIndex) revert Crate__InvalidRange();
        if (rate > BASIS_POINTS) revert Crate__InvalidRewardRate();

        for (uint256 i = startIndex; i <= endIndex; i++) {
            index_RewardRate[i] = rate;
            emit Crate__IndexSet(i, rate);
        }
    }

    function setMaxIndex(uint256 _maxIndex) external onlyOwner {
        maxIndex = _maxIndex;
        emit Crate__MaxIndexSet(_maxIndex);
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert Crate__InvalidZeroAddress();
        treasury = _treasury;
        emit Crate__TreasurySet(treasury);
    }

    function setDeveloper(address _developer) external {
        if (msg.sender != developer) revert Crate__NotDeveloper();
        if (_developer == address(0)) revert Crate__InvalidZeroAddress();
        developer = _developer;
        emit Crate__DeveloperSet(developer);
    }

    function setIncentives(address _incentives) external onlyOwner {
        if (_incentives == address(0)) revert Crate__InvalidZeroAddress();
        incentives = _incentives;
        emit Crate__IncentivesSet(incentives);
    }

    /*----------  VIEW FUNCTIONS  ---------------------------------------*/

    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

}
