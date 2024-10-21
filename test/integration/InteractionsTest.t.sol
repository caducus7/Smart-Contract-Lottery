//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig, CodeConstants} from "../../script/HelperConfig.s.sol";

contract InteractionsTest is Test, CodeConstants {
    Raffle public raffle;
    DeployRaffle public deployRaffle;
    HelperConfig public helperConfig;
    address public USER = makeAddr("user");

    uint256 constant STARTING_USER_BALANCE = 10 ether;
    event PickedWinner(address indexed winner);
    event RaffleEntered(address indexed player);
    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    uint256 subscriptionId;
    address linkToken;

    function setUp() external {
        deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(USER, STARTING_USER_BALANCE);
    }
}
