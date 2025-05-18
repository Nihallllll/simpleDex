// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract SimpleDex is ERC20 {

    IERC20 public token ;
    uint256 public  ethReserve;
    uint256 public tokenReserve;

    //events
    event LiquidityAdded(address provider, uint256 ethAmount, uint256 tokenAmount);
    event LiquidityRemoved(address provider, uint256 ethAmount, uint256 tokenAmount);
    event EthToTokenSwap(address swapper, uint256 ethAmount, uint256 tokenAmount);
    event TokenToEthSwap(address swapper, uint256 tokenAmount, uint256 ethAmount);


    constructor(address _token) ERC20("LP Token","LPT"){
       token = IERC20(_token);
    }


    //function to add liquidity 
    function addLiquidity(uint256 tokenAmount) payable public {
      uint256 ethAdded = msg.value;
      if (totalSupply() == 0) {
         require(tokenAmount > 0 && ethAdded > 0 , "Not enough token added");
         token.transferFrom(msg.sender, address(this), tokenAmount);
         ethReserve = ethAdded;
         tokenReserve = tokenAmount;
         _mint(msg.sender, ethAdded);
      } else {
           uint256 requiredTokenAmount =(ethAdded * tokenReserve)/ ethReserve ;
           require(tokenAmount == requiredTokenAmount ,"Not Enough Amount");
           token.transferFrom(msg.sender, address(this), tokenAmount);
           uint256  lpTokens = (ethAdded * totalSupply())/ ethReserve; 
           _mint(msg.sender, lpTokens);
           ethReserve += ethAdded;
           tokenReserve += tokenAmount;
      }
      emit LiquidityAdded(msg.sender, ethAdded, tokenAmount);
    }

    function removeLiquidity(uint256 lpAmount) public{
      require(lpAmount > 0  && lpAmount <= balanceOf(msg.sender),"Not valid amount");
      uint256 ethToBeTaken = (lpAmount * ethReserve) / totalSupply();
      uint256 tokenToBeTaken = (lpAmount * tokenReserve)/ totalSupply();
      _burn(msg.sender, lpAmount);
      payable(msg.sender).transfer(ethToBeTaken);
      token.transfer(msg.sender, tokenToBeTaken);
      ethReserve -= ethToBeTaken;
      tokenReserve -= tokenToBeTaken;
      emit LiquidityRemoved(msg.sender, ethToBeTaken, tokenToBeTaken);
    }
    
    //this function calculates how much of token A , you will get in return of token B
    function getAmountOut(uint inputAmount, uint reserveIn, uint reserveOut) public pure returns (uint) {
      require(inputAmount > 0 && reserveIn >0 && reserveOut > 0 ,"Not a valid purchase");
      uint256 numerator = inputAmount * reserveOut;
      uint256 denominator = reserveIn + inputAmount;
      return numerator / denominator;
    }

    function ethToToken() public payable{
      require(msg.value >0 ,"Add a valid amount");
      uint256 inputAmount = msg.value;
      uint256 outPutAmount = getAmountOut(inputAmount, ethReserve, tokenReserve);
      token.transfer(msg.sender, outPutAmount);
      ethReserve += inputAmount;
      tokenReserve -= outPutAmount;
      emit EthToTokenSwap(msg.sender, inputAmount, outPutAmount);
    }

    function tokenToEth(uint256 _amount) public{
      require(_amount > 0 ,"Not a valid amount" );
      uint outPutAmount = getAmountOut(_amount, tokenReserve, ethReserve);
      token.transferFrom(msg.sender, address(this), _amount);
      payable(msg.sender).transfer(outPutAmount);
      tokenReserve += _amount;
      ethReserve -= outPutAmount;
      emit TokenToEthSwap(msg.sender, _amount , outPutAmount );

    }
    receive() external payable {}
}
