//SPX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract RaffleTest is Test, CodeConstants {
    Raffle public raffle;
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
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;

        vm.deal(USER, STARTING_USER_BALANCE);
    }

    modifier UpkeepReady() {
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != LOCAL_CHAIN_ID) {
            return;
        }
        _;
    }

    function testRaffleIsOpenAtInit() public view {
        assertEq(uint256(raffle.getRaffleState()), 0);
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.prank(USER);

        raffle.enterRaffle{value: entranceFee}();

        raffle.getPlayer(0);

        assertEq(raffle.getPlayer(0), USER);
    }

    function testEnterEventEmit() public {
        //Arrange
        vm.prank(USER);
        //Act
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(USER);
        //assert
        raffle.enterRaffle{value: entranceFee}();
    }

    function testPlayersNotAllowedToEnterCalculatingState() public UpkeepReady {
        // Arrange
        //modifier
        raffle.performUpkeep("");
        // Act
        vm.expectRevert(Raffle.Raffle__RaffleNotOpen.selector);
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();

        // Assert
    }

    ////////Check UpKeep//////////

    function testCheckUpkeepReturnsFalseIfRaffleIsntOpen() public UpkeepReady {
        // Arrange
        //modifier
        raffle.performUpkeep("");
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assertEq(upkeepNeeded, false);
    }

    function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        //Arrange
        vm.prank(USER);
        raffle.enterRaffle{value: entranceFee}();

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenParametersAreMet()
        public
        UpkeepReady
    {
        //Arrange
        //modifier
        //Act

        bool raffleState = raffle.getRaffleState() == Raffle.RaffleState.OPEN;
        bool hasPlayers = raffle.hasPlayer();
        bool hasBalance = address(raffle).balance > 0;
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(raffleState);
        assert(hasPlayers);
        assert(hasBalance);
        assertEq(upkeepNeeded, true);
    }

    ///// PERFORM UPKEEP //////

    function testPerformUpkeepRunsIfUpkeepNeeded() public UpkeepReady {
        //Arrange
        //modifier
        //Act/Assert
        raffle.performUpkeep("");
    }

    function testPerformUpkeepIfCheckUpkeepReturnsFalse() public {
        //Arrange
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState = raffle.getRaffleState();
        // Act / Assert
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotNeeded.selector,
                currentBalance,
                numPlayers,
                rState
            )
        );
        raffle.performUpkeep("");
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId()
        public
        UpkeepReady
    {
        //Arrange
        //modifier
        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        //Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert((uint256(raffleState) == 1));
    }

    //////////FULFILL RANDOM WORDS////////

    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(
        uint256 randomRequestId
    ) public UpkeepReady skipFork {
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    /////////// WINNER TEST //////////
    function testFulfillRandomWordsPicksAWinnerAndSendsMoney()
        public
        UpkeepReady
        skipFork
    {
        //Arrange
        uint256 additionalPlayers = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalPlayers;
            i++
        ) {
            address player = address(uint160(i));
            hoax(player, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        VRFCoordinatorV2_5Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        //Assert
        address recentWinner = raffle.getRecentWinner();
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        uint256 winnerBalance = recentWinner.balance;
        uint256 endingTimeStamp = raffle.getLastTimeStamp();
        uint256 prize = entranceFee * (additionalPlayers + 1); //additionalPlayer (3) + modifier-created player (1)

        assertEq(recentWinner, expectedWinner);
        assert(uint256(raffleState) == 0);
        assertEq(winnerBalance, winnerStartingBalance + prize);
        assertEq(endingTimeStamp > startingTimeStamp, true);
    }
}