// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// install from https://github.com/smartcontractkit/chainlink-brownie-contracts
// forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 @ specify version
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/**
 * @title A Sample Raffle Contract
 * @author VDP
 * @notice This contract is for creating a simple raffle system.
 * @dev Implements Chainling VRFv2.5
 */
contract Raffle is VRFConsumerBaseV2Plus {
    /* ERRORS */
    error Raffle__SendMoreToEnterRaffle();
    error Raffle__TransferError();
    error Raffle__RaffleNotOpen();
    Raffle__TransferError Raffle__UpkeepNotNeeded(uint256 balance, uint256 numPlayers, uint256 raffleState);



    /* TYPE DECLARATIONS */
    // @ notice want avoid enter the raffle while calculating the winner
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    /* STATE VARIABLES */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    //@dev the duration of the lottery in seconds
    uint256 private immutable i_interval;
    uint32 private immutable i_callbackGasLimit;
    bytes32 private immutable i_keyhash;
    uint256 private immutable i_subscriptionId;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /* EVENTS */
    event RaffleEnterd(address indexed player);
    event WinnerPicked(address indexed winner);

    // need to expand constructor
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint256 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        i_keyhash = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        // use require
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter the raffle");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle()); // v0.8.26
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }

        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnterd(msg.sender);
    }

    function checkUpkeep(bytes calldata /* checkData */) public view returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed = block.timestamp - s_lastTimeStamp >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers; 
        // "0x0" return null 
        return (upkeepNeeded, "0x0");

        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    // 1. get random num
    // 2. call automatically

    /**
     * @dev This is the function that Chainlink VRF will call to get a random winner.
     * The following shold be true
     */
    function performUpkeep(bytes calldata /* performData */) external {
        // check if enough time has passed
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;
        // get random number from chainlink
        // 1. request RNG
        // 2. get RNG

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyhash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: REQUEST_CONFIRMATIONS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
        });

        requestId = s_vrfCoordinator.requestRandomWords(request);
    }

    // call by rawFulfillRandomWords
    // CEI pattern
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        // checks
        //Effects
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;

        // reset the raffle
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        emit WinnerPicked(recentWinner);

        // Interactions
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferError();
        }

    }

    /**
     * Getter functions
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }
}
