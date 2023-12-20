// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    FundMe fundMe;
    address TestUser = makeAddr("TestUser"); // create fake test user address
    uint256 public constant SEND_VALUE = .1 ether;
    uint256 public constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(TestUser, 10e18);  // give the fake user address some ether
    }

    /**
     * @notice  .
     * @dev     .
     */
    modifier funded() {
        vm.prank(TestUser);
        fundMe.fund{value: 10e18}();
        _;
    }

    function testMinimumUSD() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testIsOwner() public {
        // test owner of FundMe is FundMeTest...
        // since FundMeTest deployed FundME, FundMeTest should be the owner of FundMe
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testAggregatorV3Interface() public {
        uint256 ver = fundMe.getVersion();
        assertEq(ver, 4);
    }

    function testInsuffiecentFunds () public {
        vm.expectRevert();
        // this should revert since         
        fundMe.fund();
    } 

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(TestUser);
        assertEq(amountFunded, 10e18);
    }  

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, TestUser);
    } 

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();  
    }

    function testWithdrawWithASingleFunder() public {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 gasStart = gasleft();
        console.log("start gas price %d", tx.gasprice);
        vm.txGasPrice(GAS_PRICE);
        console.log("gas price %d gasStart %d", tx.gasprice, gasStart);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gas used", gasUsed);


        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleUsers() public {
        uint160 numOfFunders = 10;
        uint160 startingFunderIndex = 1;  // don't use '0' since we will be using this index to generate addresses

        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        for(uint160 index = startingFunderIndex; index < numOfFunders; index++)
        {
            hoax(address(index), SEND_VALUE); // hoax creates and funds address for testing (forge stdlib)
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gas used", gasUsed);
        
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawUpdatesFundedDataStructure() public funded  {
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        uint256 amountRemaining = fundMe.getAddressToAmountFunded(TestUser);
        assertEq(amountRemaining, 0);
    }  

    // function testRemovesFunderFromArrayOfFunders() public {
    //     vm.prank(TestUser);
    //     fundMe.fund{value: 10e18}();

    //     vm.prank(msg.sender);
    //     fundMe.withdraw();
    //     address funder = fundMe.getFunder(0);
    //     assertNotEq(funder, TestUser);
    // } 
}