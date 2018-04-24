pragma solidity ^0.4.21;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

} 

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; 
}

contract Token {

    using SafeMath for uint256;
    
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] > _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public  returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public  returns (bool success) {    
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] > _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(_value < allowance[_from][msg.sender]);   // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);                          // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                            // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    } 
}

contract LotteryToken is Ownable, Token {
    using SafeMath for uint256;
    uint256 public priceForSell = 100000000000000;
    uint256 public priceForBuy = 100000000000000;

    mapping (address => bool) public frozenAccount;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address target, bool frozen);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function LotteryToken(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) public Token (initialSupply, tokenName, decimalUnits, tokenSymbol) {}

    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] > _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(!frozenAccount[msg.sender]);                // Check if frozen
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }


    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!frozenAccount[_from]);                     // Check if frozen            
        require(balanceOf[_from] > _value);                // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(_value < allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = balanceOf[_from].sub(_value);   // Subtract from the sender
        balanceOf[_to] = balanceOf[_to].add(_value);        // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function mintToken(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    function setPrices(uint256 newPriceForSell, uint256 newPriceForBuy) public onlyOwner {
        priceForSell = newPriceForSell;
        priceForBuy = newPriceForBuy;
    }

    function buy() public  payable {
        uint amount = msg.value.div(priceForBuy);                // calculates the amount
        //require(balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);                   // adds the amount to buyer's balance
        balanceOf[this] = balanceOf[this].add(amount);                         // subtracts amount from seller's balance
        emit Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }

    function sell(uint256 amount) public {
        require(balanceOf[msg.sender] > amount);        // checks if the sender has enough to sell
        balanceOf[this] = balanceOf[this].add(amount);                         // adds the amount to owner's balance
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);                   // subtracts the amount from seller's balance
        msg.sender.transfer(amount.mul(priceForSell));
        emit Transfer(msg.sender, this, amount);    
    }
}

contract JackPotLottery is LotteryToken {
    using SafeMath for uint256;
    
    address[100] public tickets;
    uint256 public countTickets = 100;
    uint256 public jackPot = 0;
    uint256 public ticketPrice = 10;
    uint256 public toJackPotFromEveryTicket = 4;
    uint256 public xPrize = 2;
    uint256 public lastWinNumber;
    
    event WinnersLotteriesNumbers(uint256 jackPotNumber, uint256 winnerMinNumber, uint256 winnerMaxNumber);
    event LotteryBought(uint256 LotteryNumber);

    function JackPotLottery() public LotteryToken(countTickets * ticketPrice, "Super Lottery Token", 0, "SLT") {
        clearTickets();
    }

    function buyTicket(uint256 ticketNum) public returns (bool success) {
        require((ticketNum > 0) || (ticketNum <= countTickets));
        require(balanceOf[msg.sender] >= ticketPrice);
        require(tickets[ticketNum] == 0);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(ticketPrice);
        jackPot = jackPot.add(toJackPotFromEveryTicket);
        tickets[ticketNum] = msg.sender;
        emit LotteryBought(ticketNum);
        return true;
    } 
    
    function play() public onlyOwner {
        lastWinNumber = uint256(block.blockhash(block.number - 1)) % countTickets + 1;
        if(tickets[lastWinNumber] != 0) {
            balanceOf[tickets[lastWinNumber]] = balanceOf[tickets[lastWinNumber]].add(jackPot);
            jackPot = 0;
        }

        //Winner number more then 0
        uint256 minNumberOfWin = lastWinNumber.sub(lastWinNumber % 10).add(1);         
        uint256 maxNumWin = minNumberOfWin.add(9);  
        
        for (uint256 i = minNumberOfWin; i < maxNumWin; i++) {
            if(tickets[i] != 0) {
                balanceOf[tickets[i]] = balanceOf[tickets[i]].add(ticketPrice * xPrize); 
            }
        }
        emit WinnersLotteriesNumbers(lastWinNumber, minNumberOfWin, maxNumWin);
        clearTickets();
    }

    function setLotteryParameters (uint256 newTicketPrice, uint256 newToJackPotFromEveryTicket, uint256 newXPrize) public onlyOwner {
        ticketPrice = newTicketPrice;
        toJackPotFromEveryTicket = newToJackPotFromEveryTicket;
        xPrize = newXPrize;
    }
    
    function clearTickets() private {
        for (uint256 j = 0; j < countTickets; j++) {
            tickets[j] = 0;
        }
    }
}
