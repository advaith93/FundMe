//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";


contract FundMeTest is Test {
    FundMe fundMe;
    address alice = makeAddr("alice");
    uint256 constant SEND_VALUE = 10e18;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;
   

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
         vm.deal(alice, STARTING_BALANCE);
    }

    function testOwnerIsMSGSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);

    }

    function testMinimumDollasIsFive() public view{
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

   function testPriceFeedVersionIsAccurate() public view {
    uint256 version = fundMe.getVersion();
    assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundDataStructure() public {
        vm.prank(alice);
        fundMe.fund{value : SEND_VALUE}();

        uint amountFunded = fundMe.getAddressToAmountFunded(alice);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToFundersArray() public {
        vm.prank(alice);
        fundMe.fund{value : SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, alice);
    }


    modifier funded()
    {
        vm.prank(alice);
        fundMe.fund{value : SEND_VALUE}();
        _;
    }



    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(alice);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded{
        //Arrange
       uint256 startingFundMeBalance = address(fundMe).balance;
       uint256 startingOwnerBalance = fundMe.getOwner().balance;
        //Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    uint256 gasEnd = gasleft();
    uint256 gasUsed = (gasStart-gasEnd) * tx.gasprice;
    console.log(gasUsed);
        vm.stopPrank();
        //Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
    assertEq(endingFundMeBalance, 0);
    assertEq(
    startingFundMeBalance + startingOwnerBalance,
    endingOwnerBalance);
    }
 

    function testWithDrawFromMultipleFunders() public funded{
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value : SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
       uint256 startingOwnerBalance = fundMe.getOwner().balance;

       vm.prank(fundMe.getOwner());
       fundMe.withdraw();
       vm.stopPrank();

       assert(address(fundMe).balance == 0);
       assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithDrawFromMultipleFundersCheaper() public funded{
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++){
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value : SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
       uint256 startingOwnerBalance = fundMe.getOwner().balance;

       vm.prank(fundMe.getOwner());
       fundMe.cheaperWithdraw();
       vm.stopPrank();

       assert(address(fundMe).balance == 0);
       assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}