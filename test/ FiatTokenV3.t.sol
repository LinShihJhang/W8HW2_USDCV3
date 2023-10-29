// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {FiatTokenV3} from "../src/FiatTokenV3.sol";

interface IFiatTokenProxy {
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable;

    function upgradeTo(address newImplementation) external;

    function admin() external view returns (address);
}

contract FiatTokenV3Test is Test {
    FiatTokenV3 public fiatTokenV3;
    FiatTokenV3 public proxyFiatTokenV3;
    IFiatTokenProxy public usdcFiatTokenProxy;

    address usdcOwner = 0xFcb19e6a322b27c06842A71e8c725399f049AE3a;
    address usdcAdmin = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    address usdcFiatTokenProxyAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    address user1 = makeAddr("user1");
    address user2InWhitelist = makeAddr("user2InWhitelist");
    address user3 = makeAddr("user3");

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString("AlchemyAPI"));
        vm.selectFork(forkId);

        vm.startPrank(usdcAdmin);
        fiatTokenV3 = new FiatTokenV3();
        usdcFiatTokenProxy = IFiatTokenProxy(usdcFiatTokenProxyAddress);
       
        //upgrade usdcV3
        usdcFiatTokenProxy.upgradeTo(address(fiatTokenV3));
        proxyFiatTokenV3 = FiatTokenV3(address(usdcFiatTokenProxy));

        //vm.load(usdcFiatTokenProxyAddress, 0x10d6a54a4754c8869d6886b5f5d7fbfa5b4522237ea5c60d11bc4e7a1ff9390b);
        //console2.log(usdcFiatTokenProxy.admin());
        vm.stopPrank();


        //usdcV3 initializeV3
        vm.startPrank(usdcOwner);
        uint256 proxyFiatTokenInitializeVersion = proxyFiatTokenV3.initializeV3(usdcOwner);
        //require(proxyFiatTokenInitializeVersion == 3, "initializeV3 failed");
        assertEq(proxyFiatTokenInitializeVersion , 3);

        //add whitelist
        proxyFiatTokenV3.whitelist(user2InWhitelist);
        assertTrue(proxyFiatTokenV3.isWhitelisted(user2InWhitelist));
        assertFalse(proxyFiatTokenV3.isWhitelisted(user1));

        // require(
        //     proxyFiatTokenV3.isWhitelisted(user2InWhitelist),
        //     "user2InWhitelist is not whitelisted"
        // );

        // require(
        //     !proxyFiatTokenV3.isWhitelisted(user1),
        //     "user1 is whitelisted, but user1 can not in whitelist"
        // );

        deal(address(usdcFiatTokenProxyAddress), user1, 50e18);
        deal(address(usdcFiatTokenProxyAddress), user2InWhitelist, 50e18);

        vm.stopPrank();

    }

    function testTransfer() public {

        //without whitelist
        vm.startPrank(user1);
        vm.expectRevert("Whitelistable: account is not whitelisted");
        proxyFiatTokenV3.transfer(user3, 10e18);
        vm.stopPrank();

        //in whitelist
        vm.startPrank(user2InWhitelist);
        proxyFiatTokenV3.transfer(user3, 10e18);
        assertEq(proxyFiatTokenV3.balanceOf(user3) , 10e18);
        //require(proxyFiatTokenV3.balanceOf(user3) == 10e18, "user2InWhitelist transfer failed");
        vm.stopPrank();

        
    }

    function testMint() public {

        uint256 beforeMint = proxyFiatTokenV3.totalSupply();
        //without whitelist
        vm.startPrank(user1);
        vm.expectRevert("Whitelistable: account is not whitelisted");
        proxyFiatTokenV3.mintV3(user3, 5e18);
        vm.stopPrank();

        //in whitelist
        vm.startPrank(user2InWhitelist);
        proxyFiatTokenV3.mintV3(user3, 500e18);
        assertEq(proxyFiatTokenV3.balanceOf(user3) , 500e18);
        assertEq(proxyFiatTokenV3.totalSupply() - beforeMint ,500e18);
        // require(proxyFiatTokenV3.balanceOf(user3) == 500e18, "user2InWhitelist mint failed");
        // require(proxyFiatTokenV3.totalSupply() - beforeMint == 500e18, "totalSupply_ - beforeMint != 500e18");
        vm.stopPrank();

    }

}
