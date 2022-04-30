// SPDX-License-Identifier: MIT
// Define the version of solidity that we are going to use
pragma solidity ^0.8.7;
// Defining a custom error. We use this since they are more gas efficient. Look more into custom errors.
error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();
// N.B: An important obsrevation, as a coding standard it is better to define the variable type i.e by "s_" / "i_". to let the developers know the
// type of the variable that they are dealing with

// Define the contract
contract Raffle{
    // Defining enum to establish the state of the smart contract 
    // An enum is a datatype which can only have a fixed number of values and nothing beyond it
    // N.B: Although for only two states a bool could have been better, even unit256 are better gas wise
    // The below has been done for more code readability
    enum RaffleState {
        Open,
        Calculating
    }
    // A state variable to keep track of the state of the smart contract. Since storage defined by "s_".
    // Recap: Variables which are global are by default state/storage. Variables that are inside the functions, unless in some cases are in memory.
    RaffleState public s_raffleState;
    // Global variable for the entrance fee. "i_" is defined to let devs know that using this will be cheap
    uint256 public immutable i_entranceFee;
    address payable[] public s_players;
    // Define an event when a new user is onboarded into the lottery
    // Look into properly what the parameters mean
    event RaffleEnter(address indexed player);
    // Constructor definition
    constructor(uint256 entranceFee) {
        i_entranceFee = entranceFee;
    }

    // Function for entering the lottery
    function enterRaffle() external payable {
        // Performing initial checks to verify if the proper entrance fee has been paid or not and to check the state of the contract if it is open
        // or not
        
        // Not using require with the string as it is not gas friendly
        // require(msg.value > i_entranceFee, "Not enough money sent !!");
        if (msg.value < i_entranceFee) {
            // reverting the custom error
            // look more into the reverting keyword
            revert Raffle__SendMoreToEnterRaffle();
        }
        // Open Calculating a winner
        // First check the state of the smart-contract if it is open or not
        if(s_raffleState != RaffleState.Open) {
            revert Raffle__RaffleNotOpen();
        }
        // After verifying the above checks proceed to onboard the users to onboard into the lottery
        // You can enter
        s_players.push(payable(msg.sender));
        // Emitting the event with the user address
        emit RaffleEnter(msg.sender);
    }

    // N.B: To select a winner we want to
    // 1. Do this automatically
    // 2. We want a real random winner

    // Checkout ChainLink Keepers and find out how the function, like an event trigerring some transaction on the blockchain

    // 1. Be True after certian time intervals
    // 2. The lottery has to be open
    // 3. The contract has ETH
    // 4. Keepers has LINK

    // Checkout further the functionality of this Keepes function
    // N.B: From preliminary understanding this is a function which checks for a number of conditions if the 
    function checkUpKeep(
        bytes memory /* checkData */
    ) public view returns(
        bool upkeepNeeded, bytes memory /* performData */
        ){

    }



}