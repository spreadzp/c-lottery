// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";

// Import libraries we need.
import { default as Web3 } from 'web3';
import { default as contract } from 'truffle-contract'

// Import our contract artifacts and turn them into usable abstractions.
//import metacoin_artifacts from '../../build/contracts/MetaCoin.json'
import jackPotLottery_artifacts from '../../build/contracts/JackPotLottery.json'

// MetaCoin is our usable abstraction, which we'll use through the code below.
//var MetaCoin = contract(metacoin_artifacts);
var JackPotLottery = contract(jackPotLottery_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;
var listLottery;

window.App = {

  start: function () {
    var self = this;

    // Bootstrap the MetaCoin abstraction for Use.
    //MetaCoin.setProvider(web3.currentProvider);
    JackPotLottery.setProvider(web3.currentProvider);

    // Get the initial account balance so it can be displayed.
    web3.eth.getAccounts(function (err, accs) {
      if (err != null) {
        alert("There was an error fetching your accounts.");
        return;
      }

      if (accs.length == 0) {
        alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
        return;
      }

      accounts = accs;
      account = accounts[0];

      self.refreshBalance();
      self.refreshAmount();
    });
  },

  sellTokens: function (tokens) {
    var self = this,
    tokensForSale = document.getElementById('numberTokensForSale'); 
    if(tokensForSale.value != 0) {
      console.log('tokens :', tokensForSale.value);
      tokensForSale.value = 0;
    } else {
      alert('Enter number tokens for sale!')
    }
  },
  refreshAmount: function () {
    var self = this,
      amounttoken = document.getElementById("amounttoken");

    JackPotLottery.deployed().then(function (instance) {
      var jackPot = instance;
      return jackPot.balanceOf.call(account, { from: account });
    }).then(function (value) {
      amounttoken.innerHTML = value.valueOf() + "&nbsp;";
    }).catch(function (e) {
      console.log(e);
      self.setStatus("Error getting balance; see log.");
    });

  },

  play: function () {
    var jackPotField = document.getElementById('jackpot'),
      lotteryAmount = document.getElementById('yourlotteries'),
      winnersField = document.getElementById('winlottery'),
      self = this,
      jackPot,
      jackPotSum,
      xPrize;

    JackPotLottery.deployed().then(function (instance) {
      jackPot = instance;
      return jackPot.jackPot.call(account, { from: account });
    }).then(function (sumJackPot) {
      jackPotSum = sumJackPot.valueOf();
      return jackPot.xPrize.call(account, { from: account });
    })
      .then(function (prize) {
        xPrize = prize.valueOf();
        return jackPot.ticketPrice.call(account, { from: account });
      })
      .then(function (ticketPrice) {
        xPrize = xPrize * ticketPrice.valueOf();
        jackPot.play({ from: account, gas: 5000000 });
      })
      .then(function () {
        var latestBlock = web3.eth.blockNumber, //get the latest blocknumber
          events = jackPot.WinnersLotteriesNumbers({ fromBlock: latestBlock });

        events.watch(function (error, result) {
          if (error) {
            console.log(error); return;
          } else {
            const { args } = result;
            const { jackPotNumber, winnerMinNumber, winnerMaxNumber } = args;
            if (result.blockNumber === latestBlock) {   //accept only new events
              console.log(result);
              alert(`Jackpot lottery number ${jackPotNumber.valueOf()} won sum ${jackPotSum} tokens \n` +
                `Lottery numbers won from ${winnerMinNumber.valueOf()} to ${winnerMaxNumber.valueOf()}. Sum of the one prize ${xPrize} tokens`);
              latestBlock = latestBlock + 1;   //update the latest blockNumber
            }
          }
        })
      }).then(function () {
        self.getFreeLottery();
        self.refreshAmount();
        lotteryAmount.innerHTML = '';
      }).catch(function (e) {
        console.log(e);
      });
  },

  getFreeLottery: function () {
    var listlotteries = document.getElementById("listlottery"),
      freeLotteries = '';

    for (let j = 1; j < 101; j++) {
      freeLotteries += `
      <a class="round-button" onclick="return App.buyLottery(this)"
      title="Click button for buy the lottery #${j}">${j}</a>`;
    }
    listlotteries.innerHTML = freeLotteries;
  },
  buyLottery: function (element) {
    var self = this,
      jackPot,
      lotteryAmount = document.getElementById('yourlotteries');

    JackPotLottery.deployed().then(function (instance) {
      jackPot = instance;
      return jackPot.buyTicket(+element.innerText, { from: account, gas: 200000 });
    }).then(function (value) {
      element.onclick = '';
      element.style.color = "yellow";
      element.style.background = "center";
      element.style.cursor = "crosshair";
      element.title = '';
      self.refreshAmount();

    }).then(function () {
      lotteryAmount.innerHTML += element.innerText + "&nbsp;";
    }).catch(function (e) {
      console.log(e);
    });
  },

  /* setStatus: function (message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  }, */

 /*  refreshBalance: function () {
    var self = this,
      meta;

    MetaCoin.deployed().then(function (instance) {
      meta = instance;
      return meta.getBalance.call(account, { from: account });
    }).then(function (value) {
      var balance_element = document.getElementById("balance");
      balance_element.innerHTML = value.valueOf();

    })
      .catch(function (e) {
        console.log(e);
        self.setStatus("Error getting balance; see log.");
      });
  },

  sendCoin: function () {
    var self = this,

      amount = parseInt(document.getElementById("amount").value),
      receiver = document.getElementById("receiver").value;

    this.setStatus("Initiating transaction... (please wait)");

    var meta;
    MetaCoin.deployed().then(function (instance) {
      meta = instance;
      return meta.sendCoin(receiver, amount, { from: account });
    }).then(function () {
      self.setStatus("Transaction complete!");
      self.refreshBalance();
    }).catch(function (e) {
      console.log(e);
      self.setStatus("Error sending coin; see log.");
    });
  },

  getBalance: function () {
    var self = this,
      address = document.getElementById("address").value;

    console.log('address :', address);
    this.setStatus("Initiating transaction... (please wait)");

    var meta;
    MetaCoin.deployed().then(function (instance) {
      meta = instance;
      return meta.getBalance(address, { from: account });
    }).then(function (bal) {
      var lastBalance = document.getElementById('balanceCoin');
      lastBalance.innerHTML = bal.valueOf();
      console.log('bal :', bal);
    }).catch(function (e) {
      console.log(e);
      self.setStatus("get balance address; see log.");
    });
  }
} */
}

window.addEventListener('load', function () {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://127.0.0.1:9545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://127.0.0.1:9545"));
  }

  App.start();
});
