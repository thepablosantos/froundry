// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract ZKVerifyDeFi is ReentrancyGuard {
    struct Pool {
        address tokenAddress;
        uint256 totalStaked;
        AggregatorV3Interface priceFeed;
    }

    struct StakeInfo {
        uint256 amount;
        uint256 startTime;
        bytes32 commitment;
        bool revealed;
    }

    address public owner;
    uint256 public apy; // dynamic APY base value

    mapping(bytes32 => Pool) public pools;
    mapping(address => mapping(bytes32 => StakeInfo)) public stakes;

    event PoolCreated(bytes32 poolId, address token);
    event Committed(address indexed user, bytes32 poolId, bytes32 commitment);
    event Revealed(address indexed user, bytes32 poolId, uint256 amount);
    event Withdrawn(address indexed user, bytes32 poolId, uint256 amount);
    event PartialWithdrawn(address indexed user, bytes32 poolId, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Apenas o dono pode chamar esta funcao");
        _;
    }

    constructor(uint256 _apy) {
        owner = msg.sender;
        apy = _apy;
    }

    function createPool(address token, address priceFeed) external onlyOwner returns (bytes32) {
        bytes32 poolId = keccak256(abi.encodePacked(token, block.timestamp));
        pools[poolId] = Pool({
            tokenAddress: token,
            totalStaked: 0,
            priceFeed: AggregatorV3Interface(priceFeed)
        });
        emit PoolCreated(poolId, token);
        return poolId;
    }

    function commitStake(bytes32 poolId, bytes32 commitment) external {
        require(stakes[msg.sender][poolId].commitment == 0, "Commitment ja existe");
        stakes[msg.sender][poolId].commitment = commitment;
        emit Committed(msg.sender, poolId, commitment);
    }

    function revealStake(bytes32 poolId, uint256 amount, bytes32 salt) external nonReentrant {
        require(pools[poolId].tokenAddress != address(0), "Pool inexistente");
        require(!stakes[msg.sender][poolId].revealed, "Ja revelado");
        bytes32 hash = keccak256(abi.encodePacked(amount, salt));
        require(hash == stakes[msg.sender][poolId].commitment, "Commitment incorreto");

        IERC20 token = IERC20(pools[poolId].tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Transferencia falhou");

        stakes[msg.sender][poolId].amount = amount;
        stakes[msg.sender][poolId].startTime = block.timestamp;
        stakes[msg.sender][poolId].revealed = true;
        pools[poolId].totalStaked += amount;

        emit Revealed(msg.sender, poolId, amount);
    }

    function calculateReward(address user, bytes32 poolId) public view returns (uint256) {
        StakeInfo memory stake = stakes[user][poolId];
        if (!stake.revealed) return 0;
        uint256 timeStaked = block.timestamp - stake.startTime;
        uint256 yearlyReward = (stake.amount * getDynamicAPY(poolId)) / 10000;
        return (yearlyReward * timeStaked) / 365 days;
    }

    function withdraw(bytes32 poolId) external nonReentrant {
        StakeInfo storage stake = stakes[msg.sender][poolId];
        require(stake.revealed, "Stake nao revelado");
        uint256 reward = calculateReward(msg.sender, poolId);
        uint256 total = stake.amount + reward;

        IERC20 token = IERC20(pools[poolId].tokenAddress);
        require(token.transfer(msg.sender, total), "Falha na transferencia");

        pools[poolId].totalStaked -= stake.amount;
        delete stakes[msg.sender][poolId];

        emit Withdrawn(msg.sender, poolId, total);
    }

    function partialWithdraw(bytes32 poolId, uint256 withdrawAmount) external nonReentrant {
        StakeInfo storage stake = stakes[msg.sender][poolId];
        require(stake.revealed, "Stake nao revelado");
        require(withdrawAmount <= stake.amount, "Valor superior ao depositado");

        uint256 reward = calculateReward(msg.sender, poolId);
        uint256 proportionalReward = (reward * withdrawAmount) / stake.amount;

        IERC20 token = IERC20(pools[poolId].tokenAddress);
        require(token.transfer(msg.sender, withdrawAmount + proportionalReward), "Falha na transferencia");

        stake.amount -= withdrawAmount;
        pools[poolId].totalStaked -= withdrawAmount;

        emit PartialWithdrawn(msg.sender, poolId, withdrawAmount + proportionalReward);
    }

    function getDynamicAPY(bytes32 poolId) public view returns (uint256) {
        (, int256 price, , , ) = pools[poolId].priceFeed.latestRoundData();
        // Exemplo: aumenta APY se volatilidade for alta (mock)
        if (price > 100000000) return apy + 200; // 2% adicional
        return apy;
    }
}
