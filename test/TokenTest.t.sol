// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/MockERC20.sol";
import "../src/MockV3Aggregator.sol";

contract TokenTest is Test {
    MockERC20 public token;
    MockV3Aggregator public priceFeed;
    address public user = address(1);

    function setUp() public {
        token = new MockERC20("Test Token", "TEST", 18);
        priceFeed = new MockV3Aggregator(8, 200000000); // $2.00
    }

    function testTokenMint() public {
        uint256 amount = 1000 * 10**18;
        token.mint(user, amount);
        assertEq(token.balanceOf(user), amount);
    }

    function testPriceFeed() public {
        (, int256 price,,,) = priceFeed.latestRoundData();
        assertEq(price, 200000000);
    }
} 