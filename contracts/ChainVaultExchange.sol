// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ChainVault Exchange
 * @notice A decentralized exchange (DEX) with vault-secured liquidity pools.
 * @dev Supports ERC20 token pair swapping, liquidity adding/removal, and fee distribution.
 */

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ChainVaultExchange {
    address public admin;
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public swapFee = 25; // 0.25% (fee = swapFee / 10000)

    mapping(address => uint256) public liquidityShares;
    uint256 public totalShares;

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB);
    event Swapped(address indexed trader, address tokenIn, uint256 amountIn, uint256 amountOut);
    event UpdatedFee(uint256 newFee);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        admin = msg.sender;
    }

    /**
     * @notice Add liquidity to vault to enable swapping
     */
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 shares;
        if (totalShares == 0) {
            shares = amountA + amountB;
        } else {
            shares = (amountA * totalShares) / reserveA;
        }

        liquidityShares[msg.sender] += shares;
        totalShares += shares;

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB, shares);
    }

    /**
     * @notice Swap Token A → Token B or Token B → Token A
     */
    function swap(address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        require(amountIn > 0, "Amount must be > 0");

        bool isAtoB = tokenIn == address(tokenA);
        require(isAtoB || tokenIn == address(tokenB), "Invalid token");

        if (isAtoB) {
            tokenA.transferFrom(msg.sender, address(this), amountIn);
            uint256 amountAfterFee = amountIn - ((amountIn * swapFee) / 10000);
            amountOut = getPrice(amountAfterFee, reserveA, reserveB);

            reserveA += amountIn;
            reserveB -= amountOut;
            tokenB.transfer(msg.sender, amountOut);

            emit Swapped(msg.sender, tokenIn, amountIn, amountOut);
        } else {
            tokenB.transferFrom(msg.sender, address(this), amountIn);
            uint256 amountAfterFee = amountIn - ((amountIn * swapFee) / 10000);
            amountOut = getPrice(amountAfterFee, reserveB, reserveA);

            reserveB += amountIn;
            reserveA -= amountOut;
            tokenA.transfer(msg.sender, amountOut);

            emit Swapped(msg.sender, tokenIn, amountIn, amountOut);
        }
    }

    /**
     * @notice Remove liquidity from vault and receive both tokens
     */
    function removeLiquidity(uint256 shares) external {
        require(liquidityShares[msg.sender] >= shares, "Insufficient shares");

        uint256 amountA = (shares * reserveA) / totalShares;
        uint256 amountB = (shares * reserveB) / totalShares;

        liquidityShares[msg.sender] -= shares;
        totalShares -= shares;

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    /**
     * @notice Constant-product pricing model (x * y = k)
     */
    function getPrice(uint256 amountIn, uint256 rIn, uint256 rOut) public pure returns (uint256) {
        uint256 numerator = amountIn * rOut;
        uint256 denominator = rIn + amountIn;
        return numerator / denominator;
    }

    /**
     * @notice Admin can update swap fee
     */
    function updateSwapFee(uint256 newFee) external onlyAdmin {
        require(newFee <= 100, "Fee too high");
        swapFee = newFee;
        emit UpdatedFee(newFee);
    }
}
