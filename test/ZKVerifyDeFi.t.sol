// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ZKVerifyDeFi.sol";

contract ZKVerifyDeFiTest is Test {
    ZKVerifyDeFi public defi;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public { 
        defi = new ZKVerifyDeFi();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testCreatePool() public {
        vm.prank(alice);
        defi.createPool("Pool 1", 30 days);
        (string memory name,,,) = defi.pools(0);
        assertEq(name, "Pool 1");
    }

    function testCommitRevealAndWithdraw() public {
        vm.prank(alice);
        defi.createPool("Pool 1", 30 days);

        // Alice faz commit
        bytes32 secret = keccak256(abi.encodePacked("mysecret"));
        vm.prank(alice);
        defi.commitInvestment(0, secret);

        // Reveal com valor e seed
        vm.prank(alice);
        defi.revealInvestment{value: 2 ether}(0, 2 ether, "mysecret");

        // Espera tempo suficiente
        vm.warp(block.timestamp + 31 days);

        uint balanceBefore = alice.balance;
        vm.prank(alice);
        defi.withdraw(0);
        uint balanceAfter = alice.balance;

        assertGt(balanceAfter, balanceBefore); // Houve rendimento
    }

    function testPartialWithdraw() public {
        vm.prank(alice);
        defi.createPool("Pool 1", 30 days);
        bytes32 secret = keccak256(abi.encodePacked("secret"));

        vm.prank(alice);
        defi.commitInvestment(0, secret);

        vm.prank(alice);
        defi.revealInvestment{value: 4 ether}(0, 4 ether, "secret");

        vm.warp(block.timestamp + 15 days);

        uint before = alice.balance;
        vm.prank(alice);
        defi.partialWithdraw(0, 2 ether);
        uint afterBal = alice.balance;

        assertGt(afterBal, before);
    }

    function testInvalidRevealShouldFail() public {
        vm.prank(alice);
        defi.createPool("Pool 1", 30 days);
        bytes32 wrongSecret = keccak256(abi.encodePacked("wrong"));
        bytes32 correctSecret = keccak256(abi.encodePacked("right"));

        vm.prank(alice);
        defi.commitInvestment(0, correctSecret);

        vm.prank(alice);
        vm.expectRevert("Hash mismatch");
        defi.revealInvestment{value: 1 ether}(0, 1 ether, "wrong");
    }

    function testOnlyInvestorCanWithdraw() public {
        vm.prank(alice);
        defi.createPool("Pool 1", 30 days);
        bytes32 secret = keccak256(abi.encodePacked("mine"));

        vm.prank(alice);
        defi.commitInvestment(0, secret);

        vm.prank(alice);
        defi.revealInvestment{value: 1 ether}(0, 1 ether, "mine");

        vm.warp(block.timestamp + 31 days);

        vm.prank(bob);
        vm.expectRevert("Only investor can withdraw");
        defi.withdraw(0);
    }
}
