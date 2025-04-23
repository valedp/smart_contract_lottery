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
    error SendMoreToEnterRaffle();

    uint256 private immutable i_entranceFee;

    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "Not enough ETH to enter the raffle");
        if (msg.value < i_entranceFee) {
            revert SendMoreToEnterRaffle();
        }
    }

    function pickWinner() public {}

    /** 
     * Getter functions 
     */
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

}