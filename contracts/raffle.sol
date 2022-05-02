// SPDX-License-Identifier: MIT
// Define the version of solidity that we are going to use
pragma solidity ^0.8.7;

// Defining the Chainlink Oracle
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// Not sure why we needed this. Look more into this
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// Defining a custom error. We use this since they are more gas efficient. Look more into custom errors.
error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();
error Raffle__UpkeepNotNeeded();
error Raffle__TransferFailed();

// N.B: An important obsrevation, as a coding standard it is better to define the variable type i.e by "s_" / "i_". to let the developers know the
// type of the variable that they are dealing with

// Define the contract, we are inheriting the mentioned contract
contract Raffle is VRFConsumerBaseV2 {
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
    // Global variable for the entrance fee.
    // N.B: Check again whagt do those i_ and s_ mean ?
    // "i_" is defined to let devs know that using this will be cheap
    uint256 public immutable i_entranceFee;
    address payable[] public s_players;
    uint256 private immutable i_interval;
    uint256 public s_lastTimeStamp;
    VRFCoordinatorV2Interface public immutable i_vrfCoordinator;
    bytes32 public i_gasLane;
    uint64 public i_subscriptionId;
    uint16 public constant REQUEST_CONFIRMATIONS = 3;
    uint32 public i_callbackGasLimit;
    // Defines the number of random numbers that we want
    uint32 public constant NUM_WORDS = 1;
    address public s_recentWinner;
    // Define an event when a new user is onboarded into the lottery
    // Look into properly what the parameters mean
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    // Constructor definition
    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinatorV2,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    )
        // Find out why did we need to do this in the constructor, maybe look a the contract signature
        VRFConsumerBaseV2(vrfCoordinatorV2)
    {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
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
        if (s_raffleState != RaffleState.Open) {
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

    // Function to determine if the upkeep has to be performed or not
    // Checkout further the functionality of this Keepes function
    // N.B: From preliminary understanding this is a function which checks for a number of conditions if the required conditions are satisfied
    // for running an upkeep, i.e most likely some other off chain function will be calling it to know if the UpKeep can be performed or not
    // Some of the memory parameters are commented out because they are not required but for the compilation of the contract it should be syntactically
    // be present
    function checkUpKeep(
        bytes memory /* checkData */
    )
        public
        view
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        // Variable to store if the state of the contract is open or not
        bool isOpen = RaffleState.Open == s_raffleState;
        // Variable to check and store if the interval between the current timestamp and the previous timestamp is greater than the interval
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        // Variable to check if the contract has enough ETH balance
        bool hasBalance = address(this).balance > 0;
        // Variable to check and store if the number of players present is greater than 0
        bool hasPlayer = s_players.length > 0;
        // N.B: Since upkeepNeeded is already defined in the return signature we don't need to define it again
        // IMPORTANT way of writing a condition and storing in the variable
        upkeepNeeded = (isOpen && timePassed && hasBalance && hasPlayer);
        // Later agument is defined as a blank argument since we don't actually need it but only for syntactical purpose
        return (upkeepNeeded, "0x0");
    }

    // Function to perform the upkeep i.e trigger this to choose our winner
    function performUpKeep(
        bytes calldata /* performData */
    ) external {
        // This function will basically first check the checkUpKeep function to determine if the conditions are meet to perform the upKeep
        (bool upkeepNeeded, ) = checkUpKeep("");
        // Instead of doing a require or something we are using a if conditional statement
        if (!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded();
        }
        // Change the state of the Raffle to calculating so that no other players can be entered into the raffle
        // This is different than the Keeper, while keepers will initiate this function from outside, this will use Chainlink to generate random number
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        // Find out what event does this emit
        emit RequestedRaffleWinner(requestId);
    }

    // Find out what is a override function
    // This function is already present in the contract from which we are inheriting and will override it
    function fulfillRandomWords(
        uint256, /*requestId*/
        // An array of random numbers
        uint256[] memory randomWords
    ) internal override {
        // Find the index by the module operation by the players length
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        // Specify the recent winner by the index generated
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        // Reset our players array to 0
        s_players = new address payable[](0);
        // Reset the RaffleState
        s_raffleState = RaffleState.Open;
        // Reset the last time stamp with the current time
        s_lastTimeStamp = block.timestamp;
        // Pay the recent winner, the award is the entire amount owned by the contract i.e through the entrance fees
        // N.B: The below is actually a very good way to pay as we are just calling a adrress but not any function
        // so better use call with the payload instead of transfer or send
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit WinnerPicked(recentWinner);
    }
}
