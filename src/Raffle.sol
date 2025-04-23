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

/**
 * @title A Sample Raffle Contract
 * @author VDP
 * @notice This contract is for creating a simple raffle system.
 * @dev Implements Chainling VRFv2.5
 */

contract Raffle {
    /* ERRORS */ 
    error Raffle__SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;
    //@dev the duration of the lottery in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    /* EVENTS */
    event RaffleEnterd(address indexed player);

    constructor(uint256 entranceFee, uint256 interval) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
    }

    function enterRaffle() external payable {
        // use require
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter the raffle");
        // require(msg.value >= i_entranceFee, SendMoreToEnterRaffle()); // v0.8.26
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnterd(msg.sender);

    }

    // 1. get random num
    // 2. call automatically
    function pickWinner() external  {
        // check if enough time has passed
        if (block.timestamp - s_lastTimeStamp < i_interval){
            revert();
        }
    }

    /** 
     * Getter functions 
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

}