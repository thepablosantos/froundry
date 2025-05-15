// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ZKVerifyDeFi.sol";
import "../src/MockERC20.sol";

contract ZKVerifyDeFiTest is Test {
    ZKVerifyDeFi public defi;
    MockERC20 public token;
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public mockPriceFeed = address(0x3);

    function setUp() public { 
        vm.startPrank(alice);
        defi = new ZKVerifyDeFi(1000); // 10% APY
        token = new MockERC20("Test Token", "TEST", 18);
        vm.stopPrank();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function testCreatePool() public {
        vm.prank(alice);
        bytes32 poolId = defi.createPool(address(token), mockPriceFeed);
        
        (address tokenAddress, uint256 totalStaked, AggregatorV3Interface priceFeed) = defi.pools(poolId);
        assertEq(tokenAddress, address(token));
        assertEq(totalStaked, 0);
        assertEq(address(priceFeed), mockPriceFeed);
    }

    function testCommitRevealAndWithdraw() public {
        vm.prank(alice);
        bytes32 poolId = defi.createPool(address(token), mockPriceFeed);

        // Alice faz commit
        bytes32 salt = bytes32("mysecret");
        bytes32 commitment = keccak256(abi.encodePacked(uint256(1 ether), salt));
        vm.prank(alice);
        defi.commitStake(poolId, commitment);

        // Approve tokens
        vm.prank(alice);
        token.approve(address(defi), 1 ether);

        // Reveal com valor e salt
        vm.prank(alice);
        defi.revealStake(poolId, 1 ether, salt);

        // Espera tempo suficiente
        vm.warp(block.timestamp + 31 days);

        uint256 balanceBefore = token.balanceOf(alice);
        vm.prank(alice);
        defi.withdraw(poolId);
        uint256 balanceAfter = token.balanceOf(alice);

        assertGt(balanceAfter, balanceBefore); // Houve rendimento
    }

    function testPartialWithdraw() public {
        vm.prank(alice);
        bytes32 poolId = defi.createPool(address(token), mockPriceFeed);
        
        bytes32 salt = bytes32("secret");
        bytes32 commitment = keccak256(abi.encodePacked(uint256(4 ether), salt));
        vm.prank(alice);
        defi.commitStake(poolId, commitment);

        // Approve tokens
        vm.prank(alice);
        token.approve(address(defi), 4 ether);

        vm.prank(alice);
        defi.revealStake(poolId, 4 ether, salt);

        vm.warp(block.timestamp + 15 days);

        uint256 before = token.balanceOf(alice);
        vm.prank(alice);
        defi.partialWithdraw(poolId, 2 ether);
        uint256 afterBal = token.balanceOf(alice);

        assertGt(afterBal, before);
    }

    function testInvalidRevealShouldFail() public {
        vm.prank(alice);
        bytes32 poolId = defi.createPool(address(token), mockPriceFeed);
        
        bytes32 saltRight = bytes32("right");
        bytes32 saltWrong = bytes32("wrong");
        bytes32 commitment = keccak256(abi.encodePacked(uint256(1 ether), saltRight));
        vm.prank(alice);
        defi.commitStake(poolId, commitment);

        // Approve tokens
        vm.prank(alice);
        token.approve(address(defi), 1 ether);

        vm.prank(alice);
        vm.expectRevert("Commitment incorreto");
        defi.revealStake(poolId, 1 ether, saltWrong);
    }

    function testOnlyInvestorCanWithdraw() public {
        vm.prank(alice);
        bytes32 poolId = defi.createPool(address(token), mockPriceFeed);
        
        bytes32 salt = bytes32("mine");
        bytes32 commitment = keccak256(abi.encodePacked(uint256(1 ether), salt));
        vm.prank(alice);
        defi.commitStake(poolId, commitment);

        // Approve tokens
        vm.prank(alice);
        token.approve(address(defi), 1 ether);

        vm.prank(alice);
        defi.revealStake(poolId, 1 ether, salt);

        vm.warp(block.timestamp + 31 days);

        vm.prank(bob);
        vm.expectRevert("Stake nao revelado");
        defi.withdraw(poolId);
    }
}
