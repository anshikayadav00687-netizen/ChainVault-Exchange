// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ChainVault Exchange
 * @dev Decentralized exchange contract for token swaps with liquidity pools
 */
contract ChainVaultExchange {
    
    // State variables
    address public owner;
    uint256 public feePercentage; // Fee in basis points (100 = 1%)
    uint256 public totalLiquidity;
    
    // Mappings
    mapping(address => mapping(address => uint256)) public liquidityProviders;
    mapping(address => uint256) public tokenBalances;
    mapping(address => bool) public supportedTokens;
    
    // Events
    event LiquidityAdded(address indexed provider, address indexed token, uint256 amount);
    event LiquidityRemoved(address indexed provider, address indexed token, uint256 amount);
    event TokenSwapped(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);
    event TokenSupported(address indexed token);
    event FeeUpdated(uint256 newFee);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier validToken(address token) {
        require(supportedTokens[token], "Token not supported");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        feePercentage = 30; // Default fee: 0.3% (30 basis points)
    }
    
    /**
     * @dev Function 1: Add a new supported token to the exchange
     * @param token Address of the token to support
     */
    function addSupportedToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(!supportedTokens[token], "Token already supported");
        
        supportedTokens[token] = true;
        emit TokenSupported(token);
    }
    
    /**
     * @dev Function 2: Add liquidity to the exchange
     * @param token Address of the token
     * @param amount Amount of liquidity to add
     */
    function addLiquidity(address token, uint256 amount) external payable validToken(token) {
        require(amount > 0, "Amount must be greater than 0");
        
        if (token == address(0)) {
            // Native currency (ETH)
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            require(msg.value == 0, "Do not send ETH for token deposits");
            // In production, would use IERC20(token).transferFrom(msg.sender, address(this), amount)
        }
        
        liquidityProviders[msg.sender][token] += amount;
        tokenBalances[token] += amount;
        totalLiquidity += amount;
        
        emit LiquidityAdded(msg.sender, token, amount);
    }
    
    /**
     * @dev Function 3: Remove liquidity from the exchange
     * @param token Address of the token
     * @param amount Amount of liquidity to remove
     */
    function removeLiquidity(address token, uint256 amount) external validToken(token) {
        require(amount > 0, "Amount must be greater than 0");
        require(liquidityProviders[msg.sender][token] >= amount, "Insufficient liquidity");
        
        liquidityProviders[msg.sender][token] -= amount;
        tokenBalances[token] -= amount;
        totalLiquidity -= amount;
        
        if (token == address(0)) {
            // Native currency
            payable(msg.sender).transfer(amount);
        } else {
            // In production, would use IERC20(token).transfer(msg.sender, amount)
        }
        
        emit LiquidityRemoved(msg.sender, token, amount);
    }
    
    /**
     * @dev Function 4: Swap tokens on the exchange
     * @param fromToken Address of the token to swap from
     * @param toToken Address of the token to swap to
     * @param amountIn Amount of tokens to swap
     */
    function swapTokens(address fromToken, address toToken, uint256 amountIn) 
        external 
        payable 
        validToken(fromToken) 
        validToken(toToken) 
        returns (uint256 amountOut) 
    {
        require(amountIn > 0, "Amount must be greater than 0");
        require(fromToken != toToken, "Cannot swap same token");
        
        // Calculate output amount with fee
        uint256 fee = (amountIn * feePercentage) / 10000;
        uint256 amountAfterFee = amountIn - fee;
        
        // Simple pricing model (in production, use AMM formula)
        amountOut = (amountAfterFee * tokenBalances[toToken]) / (tokenBalances[fromToken] + amountAfterFee);
        
        require(tokenBalances[toToken] >= amountOut, "Insufficient liquidity");
        
        // Update balances
        tokenBalances[fromToken] += amountIn;
        tokenBalances[toToken] -= amountOut;
        
        emit TokenSwapped(msg.sender, fromToken, toToken, amountIn, amountOut);
        
        return amountOut;
    }
    
    /**
     * @dev Function 5: Get quote for token swap
     * @param fromToken Address of the token to swap from
     * @param toToken Address of the token to swap to
     * @param amountIn Amount of tokens to swap
     */
    function getSwapQuote(address fromToken, address toToken, uint256 amountIn) 
        external 
        view 
        validToken(fromToken) 
        validToken(toToken) 
        returns (uint256 amountOut) 
    {
        require(amountIn > 0, "Amount must be greater than 0");
        require(fromToken != toToken, "Cannot swap same token");
        
        uint256 fee = (amountIn * feePercentage) / 10000;
        uint256 amountAfterFee = amountIn - fee;
        
        amountOut = (amountAfterFee * tokenBalances[toToken]) / (tokenBalances[fromToken] + amountAfterFee);
        
        return amountOut;
    }
    
    /**
     * @dev Function 6: Update fee percentage
     * @param newFeePercentage New fee in basis points
     */
    function updateFee(uint256 newFeePercentage) external onlyOwner {
        require(newFeePercentage <= 1000, "Fee cannot exceed 10%");
        feePercentage = newFeePercentage;
        emit FeeUpdated(newFeePercentage);
    }
    
    /**
     * @dev Function 7: Get liquidity provider balance
     * @param provider Address of the liquidity provider
     * @param token Address of the token
     */
    function getLiquidityBalance(address provider, address token) 
        external 
        view 
        returns (uint256) 
    {
        return liquidityProviders[provider][token];
    }
    
    /**
     * @dev Function 8: Transfer ownership
     * @param newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner address");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    // Fallback function to receive ETH
    receive() external payable {
        tokenBalances[address(0)] += msg.value;
    }
}