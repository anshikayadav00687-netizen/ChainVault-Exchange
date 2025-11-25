State variables
    address public owner;
    uint256 public feePercentage; Mappings
    mapping(address => mapping(address => uint256)) public liquidityProviders;
    mapping(address => uint256) public tokenBalances;
    mapping(address => bool) public supportedTokens;
    
    Modifiers
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
        feePercentage = 30; Native currency (ETH)
            require(msg.value == amount, "Incorrect ETH amount");
        } else {
            require(msg.value == 0, "Do not send ETH for token deposits");
            Native currency
            payable(msg.sender).transfer(amount);
        } else {
            Calculate output amount with fee
        uint256 fee = (amountIn * feePercentage) / 10000;
        uint256 amountAfterFee = amountIn - fee;
        
        Update balances
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
    
    End
// 
// 
End
// 
