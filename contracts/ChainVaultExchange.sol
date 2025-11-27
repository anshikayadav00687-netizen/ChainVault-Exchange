// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title ChainVault Exchange
 * @notice A decentralized vault-based AMM exchange where users can deposit assets
 *         into vaults, provide liquidity and perform swaps.
 * @dev Template version. Add price oracles, audits, reentrancy guards, etc.
 */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract ChainVaultExchange {
    // -------------------------------------------------------
    // STRUCTS
    // -------------------------------------------------------
    struct Vault {
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalShares;
        mapping(address => uint256) shares;
    }

    // -------------------------------------------------------
    // STATE
    // -------------------------------------------------------
    uint256 public vaultCount;
    mapping(uint256 => Vault) public vaults;

    uint256 public constant FEE_BPS = 30;  // 0.30% swap fee
    uint256 public constant BPS_DIVISOR = 10_000;

    address public owner;

    // -------------------------------------------------------
    // EVENTS
    // -------------------------------------------------------
    event VaultCreated(
        uint256 indexed vaultId,
        address indexed token0,
        address indexed token1
    );

    event LiquidityAdded(
        uint256 indexed vaultId,
        address indexed user,
        uint256 amount0,
        uint256 amount1,
        uint256 sharesMinted
    );

    event LiquidityRemoved(
        uint256 indexed vaultId,
        address indexed user,
        uint256 amount0,
        uint256 amount1,
        uint256 sharesBurned
    );

    event Swap(
        uint256 indexed vaultId,
        address indexed user,
        address inputToken,
        uint256 inputAmount,
        uint256 outputAmount
    );

    // -------------------------------------------------------
    // MODIFIERS
    // -------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // -------------------------------------------------------
    // CONSTRUCTOR
    // -------------------------------------------------------
    constructor() {
        owner = msg.sender;
    }

    // -------------------------------------------------------
    // VAULT CREATION
    // -------------------------------------------------------
    function createVault(address token0, address token1) external onlyOwner returns (uint256) {
        require(token0 != token1, "Same token");

        vaultCount++;
        Vault storage v = vaults[vaultCount];
        v.token0 = token0;
        v.token1 = token1;

        emit VaultCreated(vaultCount, token0, token1);
        return vaultCount;
    }

    // -------------------------------------------------------
    // LIQUIDITY ADDITION
    // -------------------------------------------------------
    function addLiquidity(
        uint256 vaultId,
        uint256 amount0,
        uint256 amount1
    ) external returns (uint256 sharesMinted) {
        Vault storage v = vaults[vaultId];

        require(v.token0 != address(0), "Vault not found");

        IERC20(v.token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(v.token1).transferFrom(msg.sender, address(this), amount1);

        if (v.totalShares == 0) {
            sharesMinted = amount0 + amount1;
        } else {
            uint256 shares0 = (amount0 * v.totalShares) / v.reserve0;
            uint256 shares1 = (amount1 * v.totalShares) / v.reserve1;
            sharesMinted = shares0 < shares1 ? shares0 : shares1;
        }

        v.reserve0 += amount0;
        v.reserve1 += amount1;
        v.totalShares += sharesMinted;
        v.shares[msg.sender] += sharesMinted;

        emit LiquidityAdded(vaultId, msg.sender, amount0, amount1, sharesMinted);
    }

    // -------------------------------------------------------
    // REMOVE LIQUIDITY
    // -------------------------------------------------------
    function removeLiquidity(uint256 vaultId, uint256 shares) external returns (uint256 amount0, uint256 amount1) {
        Vault storage v = vaults[vaultId];

        require(v.shares[msg.sender] >= shares, "Not enough shares");

        amount0 = (shares * v.reserve0) / v.totalShares;
        amount1 = (shares * v.reserve1) / v.totalShares;

        v.shares[msg.sender] -= shares;
        v.totalShares -= shares;

        v.reserve0 -= amount0;
        v.reserve1 -= amount1;

        IERC20(v.token0).transfer(msg.sender, amount0);
        IERC20(v.token1).transfer(msg.sender, amount1);

        emit LiquidityRemoved(vaultId, msg.sender, amount0, amount1, shares);
    }

    // -------------------------------------------------------
    // SWAPS (Constant Product AMM: x * y = k)
    // -------------------------------------------------------
    function swap(
        uint256 vaultId,
        address inputToken,
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        Vault storage v = vaults[vaultId];

        require(inputToken == v.token0 || inputToken == v.token1, "Invalid token");

        bool isToken0In = inputToken == v.token0;
        address outputToken = isToken0In ? v.token1 : v.token0;

        IERC20(inputToken).transferFrom(msg.sender, address(this), amountIn);

        uint256 reserveIn = isToken0In ? v.reserve0 : v.reserve1;
        uint256 reserveOut = isToken0In ? v.reserve1 : v.reserve0;

        uint256 amountInAfterFee = amountIn - ((amountIn * FEE_BPS) / BPS_DIVISOR);

        // Constant-product formula
        amountOut = (reserveOut * amountInAfterFee) / (reserveIn + amountInAfterFee);

        require(amountOut > 0, "Insufficient output");

        // Update reserves
        if (isToken0In) {
            v.reserve0 += amountIn;
            v.reserve1 -= amountOut;
        } else {
            v.reserve1 += amountIn;
            v.reserve0 -= amountOut;
        }

        IERC20(outputToken).transfer(msg.sender, amountOut);

        emit Swap(vaultId, msg.sender, inputToken, amountIn, amountOut);
    }

    // -------------------------------------------------------
    // VIEW FUNCTIONS
    // -------------------------------------------------------
    function getShares(uint256 vaultId, address user) external view returns (uint256) {
        return vaults[vaultId].shares[user];
    }

    function getReserves(uint256 vaultId) external view returns (uint256 r0, uint256 r1) {
        Vault storage v = vaults[vaultId];
        return (v.reserve0, v.reserve1);
    }

    // -------------------------------------------------------
    // ADMIN
    // -------------------------------------------------------
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
