// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
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
    function redeem(address receiver, uint256 amount) external;
}

interface IBox {
    function burn(uint256 tokenId) external;
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

contract Key is ReentrancyGuard, Ownable, IEntropyConsumer {
    using SafeERC20 for IERC20;

    /*----------  CONSTANTS  --------------------------------------------*/

    uint256 public constant DEPOSIT_AMOUNT = 1 ether;
    uint256 public constant BASIS_POINTS = 10_000; // 100% = 10,000
    address public constant BGT = 0x656b95E550C07a9ffe548bd4085c72418Ceb1dba;

    /*----------  STATE VARIABLES  --------------------------------------*/

    IEntropy public entropy;

    address public immutable box;
    address public immutable vaultToken;
    address public immutable rewardVault;

    bool public initialized = false;

    uint256 public maxIndex = 100;

    mapping(uint256 => uint256) public index_RewardRate;
    mapping(uint64 => address) public sequence_Account;

    mapping(uint256 => address) public index_Token;
    mapping(uint256 => uint256) public index_TokenId;
 
    /*----------  ERRORS ------------------------------------------------*/

    error Key__InvalidZeroAddress();
    error Key__NotInitialized();
    error Key__InsufficientFee();
    error Key__InvalidSequence();
    error Key__AlreadyInitialized();
    error Key__InvalidRewardRate();
    error Key__InvalidArrayLength();
    error Key__InvalidRange();

    /*----------  EVENTS ------------------------------------------------*/

    event Key__Initialized();
    event Key__IndexSet(uint256 index, uint256 rate);
    event Key__MaxIndexSet(uint256 maxIndex);
    event Key__OpenRequest(uint64 sequenceNumber, address player);
    event Key__OpenResult(address indexed player, uint64 sequenceNumber, uint256 randomValue, uint256 rewardPercent, uint256 reward);

    /*----------  MODIFIERS  --------------------------------------------*/

    /*----------  FUNCTIONS  --------------------------------------------*/

    constructor(
        address _box,
        address _vaultFactory,
        address _entropy
    ) {
        box = _box;
        entropy = IEntropy(_entropy);
        vaultToken = address(new VaultToken());
        rewardVault = IBerachainRewardVaultFactory(_vaultFactory).createRewardVault(address(vaultToken));
    }

    receive() external payable {}

    function initialize() external {
        if (initialized) revert Key__AlreadyInitialized();
        initialized = true;

        VaultToken(vaultToken).mint(address(this), DEPOSIT_AMOUNT);
        IERC20(vaultToken).safeApprove(rewardVault, 0);
        IERC20(vaultToken).safeApprove(rewardVault, DEPOSIT_AMOUNT);
        IRewardVault(rewardVault).stake(DEPOSIT_AMOUNT);

        emit Key__Initialized();
    }

    function open(address account, bytes32 userRandomNumber, uint256 tokenId) external payable nonReentrant {
        if (!initialized) revert Key__NotInitialized();
        if (account == address(0)) revert Key__InvalidZeroAddress();

        uint256 bgtReward = IRewardVault(rewardVault).getReward(address(this), address(this));
        if (bgtReward > 0) IBGT(BGT).redeem(address(this), bgtReward);

        if (address(entropy) != address(0)) {
            address entropyProvider = entropy.getDefaultProvider();
            uint256 fee = entropy.getFee(entropyProvider);
            if (msg.value < fee) revert Key__InsufficientFee();
            uint64 sequenceNumber = entropy.requestWithCallback{value: fee}(entropyProvider, userRandomNumber);
            sequence_Account[sequenceNumber] = account;
            emit Key__OpenRequest(sequenceNumber, account);
        } else {
            userRandomNumber = keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender));
            mockCallback(account, userRandomNumber);
            emit Key__OpenRequest(0, account);
        }

        IBox(box).burn(tokenId);
    }

    /*----------  RESTRICTED FUNCTIONS  ---------------------------------*/

    function entropyCallback(
        uint64 sequenceNumber,
        address,
        bytes32 randomNumber
    ) internal override {
        address account = sequence_Account[sequenceNumber];
        if (account == address(0)) revert Key__InvalidSequence();

        uint256 randomIndex = uint256(randomNumber) % maxIndex;
        uint256 balance = address(this).balance;
        uint256 rewardPercent = index_RewardRate[randomIndex];
        uint256 reward = (balance * rewardPercent) / BASIS_POINTS;

        if (reward > 0) payable(account).transfer(reward);

        delete sequence_Account[sequenceNumber];

        address token = index_Token[randomIndex];
        if (token != address(0)) {
            uint256 tokenId = index_TokenId[randomIndex];

            delete index_Token[randomIndex];
            delete index_TokenId[randomIndex];

            IERC721(token).transferFrom(address(this), account, tokenId);

            emit Key__OpenResult(account, 0, randomIndex, rewardPercent, reward, token, tokenId);
        } else {
            emit Key__OpenResult(account, 0, randomIndex, rewardPercent, reward, address(0), 0);
        }
    }

    function mockCallback(address account, bytes32 randomValue) internal {

        uint256 randomIndex = uint256(randomValue) % maxIndex;
        uint256 balance = address(this).balance;
        uint256 rewardPercent = index_RewardRate[randomIndex];
        uint256 reward = (balance * rewardPercent) / BASIS_POINTS;

        if (reward > 0) payable(account).transfer(reward);

        address token = index_Token[randomIndex];
        if (token != address(0)) {
            uint256 tokenId = index_TokenId[randomIndex];

            delete index_Token[randomIndex];
            delete index_TokenId[randomIndex];

            IERC721(token).transferFrom(address(this), account, tokenId);

            emit Key__OpenResult(account, 0, randomIndex, rewardPercent, reward, token, tokenId);
        } else {
            emit Key__OpenResult(account, 0, randomIndex, rewardPercent, reward, address(0), 0);
        }
    }

    function setIndexToken(uint256 index, address token, uint256 tokenId) external onlyOwner {
        if (index >= maxIndex) revert Key__InvalidIndex();
        if (token == address(0)) revert Key__InvalidToken();
        if (index_Token[index] != address(0)) revert Key__TokenAlreadySet();

        IERC721(token).transferFrom(address(this), msg.sender, tokenId);

        index_Token[index] = token;
        index_TokenId[index] = tokenId;

        emit Key__IndexTokenSet(index, token, tokenId);
    }

    function setIndex(uint256 index, uint256 rate) external onlyOwner {
        if (rate >= BASIS_POINTS) revert Key__InvalidRewardRate();
        index_RewardRate[index] = rate;
        emit Key__IndexSet(index, rate);
    }

    function setIndexes(uint256[] calldata indexes, uint256[] calldata rates) external onlyOwner {
        if (indexes.length != rates.length) revert Key__InvalidArrayLength();
        for (uint256 i = 0; i < indexes.length; i++) {
            if (rates[i] > BASIS_POINTS) revert Key__InvalidRewardRate();
            index_RewardRate[indexes[i]] = rates[i];
            emit Key__IndexSet(indexes[i], rates[i]);
        }
    }

    function setIndexRange(uint256 startIndex, uint256 endIndex, uint256 rate) external onlyOwner {
        if (startIndex > endIndex) revert Key__InvalidRange();
        if (rate > BASIS_POINTS) revert Key__InvalidRewardRate();

        for (uint256 i = startIndex; i <= endIndex; i++) {
            index_RewardRate[i] = rate;
            emit Key__IndexSet(i, rate);
        }
    }

    function setMaxIndex(uint256 _maxIndex) external onlyOwner {
        maxIndex = _maxIndex;
        emit Key__MaxIndexSet(_maxIndex);
    }

    /*----------  VIEW FUNCTIONS  ---------------------------------------*/

    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

}
