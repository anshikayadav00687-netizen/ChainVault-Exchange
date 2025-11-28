-------------------------------------------------------
    -------------------------------------------------------
    struct Vault {
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalShares;
        mapping(address => uint256) shares;
    }

    STATE
    0.30% swap fee
    uint256 public constant BPS_DIVISOR = 10_000;

    address public owner;

    EVENTS
    -------------------------------------------------------
    -------------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    CONSTRUCTOR
    -------------------------------------------------------
    -------------------------------------------------------
    function createVault(address token0, address token1) external onlyOwner returns (uint256) {
        require(token0 != token1, "Same token");

        vaultCount++;
        Vault storage v = vaults[vaultCount];
        v.token0 = token0;
        v.token1 = token1;

        emit VaultCreated(vaultCount, token0, token1);
        return vaultCount;
    }

    LIQUIDITY ADDITION
    -------------------------------------------------------
    -------------------------------------------------------
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

    SWAPS (Constant Product AMM: x * y = k)
    Constant-product formula
        amountOut = (reserveOut * amountInAfterFee) / (reserveIn + amountInAfterFee);

        require(amountOut > 0, "Insufficient output");

        -------------------------------------------------------
    -------------------------------------------------------
    function getShares(uint256 vaultId, address user) external view returns (uint256) {
        return vaults[vaultId].shares[user];
    }

    function getReserves(uint256 vaultId) external view returns (uint256 r0, uint256 r1) {
        Vault storage v = vaults[vaultId];
        return (v.reserve0, v.reserve1);
    }

    ADMIN
    // -------------------------------------------------------
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
// 
Contract End
// 
