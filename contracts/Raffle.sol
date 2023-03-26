// Raffle

// Enter the lottery by paying some ETH amount
// Pick a random Winner ( Verifiable Random winner) By Chainlink VRF2

// Winner to be sellected every X Mins, Days,Month Years, --> completely automated 
// Chainlink Oracle --> Randomness , Automated execution ( Keeper )

// SPDX-License-identifier: MIT
// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

error Raffle__NotEnoughETHEnter();
error Raffle__TransactionFailed();
error Raffle__NotOpen();
error Raffle__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface{
    /* Type declations */
    enum RaffleState{
        OPEN,
        CALCULATING
    } // uint256 Rafflestate 0=OPEN, 1=CALCULATING
    /* State variable */
    uint256 private immutable i_enteranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private constant NUM_WORDS = 1;

    /* Lottery Variable*/
    address private s_recentWinner; // initiallzed with Zero Winner
    RaffleState private s_raffleState;
    uint256 private s_lastTimeStamp;
    uint256 private immutable i_interval;

    /* Events */
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    constructor (
        address vrfCoordinatorV2, 
        uint256 enteranceFee, 
        bytes32 gasLane,
        uint16  subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
        ) 
        VRFConsumerBaseV2(vrfCoordinatorV2){
        i_enteranceFee = enteranceFee;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }
    /* Functions */
    function enterRaffle() public payable{
        // require (msg.value < i_entranceFee , " NOT enough ETH")
        if(msg.value < i_enteranceFee){
            revert   Raffle__NotEnoughETHEnter();
            }
        if(s_raffleState != RaffleState.OPEN){
            revert Raffle__NotOpen();
        }
            s_players.push(payable(msg.sender));
            // emit an event when we update a dynamic array or mapping
            emit RaffleEnter(msg.sender);
    }
    /** 
     *  This function checkUpkeep222 must be TRUE to request Random Winner
     * 1. Raffle state must be in OPEN state.
     * 2. Players array must not be Zero.
     * 3. Address(this). Balance must not be Zero.
     * 4. Have Subscription have Balance of LINK token.
     * 5. Our Time Interval should have passed.
     */

    function checkUpkeep(bytes memory /*checkData*/ ) public override returns(bool upkeepNeeded, bytes memory /* performData */){
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        // (block.timestamp - last time Stamp) > interval 
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasPlayer = (s_players.length > 0);
         bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayer && hasBalance);
        return (upkeepNeeded, "0x0" );
    }

    function performUpkeep(bytes calldata /*performData*/) external override {
        (bool upkeepNeeded, ) = checkUpkeep(""); // we are passing Strings"", calldata is not working with Strings, Need to change Calldata to Memory
        if(!upkeepNeeded) {revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));}
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, // gasLane
            i_subscriptionId,
            REQUEST_CONFIRMATION,
             i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
        // request random number, when get random number Do something with it.
        // this is 2 tranaction, cause no one cane bruitforce it.
    }  // external means that only this contract call it.

    function fulfillRandomWords(uint256, /*requestId*/ uint256[] memory randomWords ) 
    internal override{
        // we use the Modulo Function 202 % 10 , 10 is the length of s_player array, 202 is Random Numbers
        // 202 % 10 = 2 , 200 is divided by 10 , while 2 Raminders, Thats mean  s_player index 2 is selected as RequestedRaffleWinner
        uint256 indexofWinner = randomWords[0] % s_players.length; //[0] means we have only 1 Randomwinner
        address payable recentWinner = s_players[indexofWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}(""); // require success
        if(!success){ revert Raffle__TransactionFailed();}
        emit WinnerPicked(recentWinner);
    }

    /* View Pure Functions */
    function getEnteranceFee() public view returns(uint256){ return i_enteranceFee; }

    function getPlayer(uint256 index) public view returns(address) {   return s_players[index];    }

    function getRecentWinner() public view returns (address){ return s_recentWinner;    }

    function getRaffleState() public view returns (RaffleState) { return s_raffleState; }

    function getNumsWords() public pure returns (uint256) { return NUM_WORDS; } // becuase NUM_WORDs constant cannot be stored in Memory,
    // thats why need to PURE instead if View.
    
    function getNumberOfPlayer() public view returns(uint256) { return s_players.length;   }

    function getLatestTimeStamp() public view returns(uint256) { return s_lastTimeStamp;   }

    function getRequestConfirmationNumber() public pure returns(uint256) { return REQUEST_CONFIRMATION;   }

    function getInterval() public view returns(uint256){ return i_interval; }
}