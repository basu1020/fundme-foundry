// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test{
    FundMe fundMe;

    address USER = makeAddr("MeAndMyself");

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, 20e18);
    }

    function testDemo() public {
        console.log("hi mom");
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testVersion() public {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        fundMe.fund();
    }

    modifier funded () {
        vm.prank(USER);
        fundMe.fund{value : 10e18}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        assertEq(fundMe.getAddressToAmountFunded(USER), 10e18);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        assertEq(fundMe.getFunder(0), USER);
    }


    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testActualWithdrawlByOwner() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfUsers = 10;
        uint160 startingFunderIndex = 1;

        uint256 gasLeftOne = gasleft();
        console.log(gasLeftOne);

        for(uint160 i = startingFunderIndex; i < numberOfUsers; i++) {
            hoax(address(i), 10e18);
            fundMe.fund{value : 10e18}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        // Act 
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert 
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}