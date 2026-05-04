// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DiveLogRegistry} from "../src/DiveLogRegistry.sol";
import {DiveLogBook, UnitSystem, DiverProfile} from "../src/DiveLogBook.sol";

contract DiveLogRegistryTest is Test {
    DiveLogRegistry public registry;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        registry = new DiveLogRegistry();
    }

    function test_registerDiver() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);

        assertTrue(registry.isRegistered(alice));
        assertEq(registry.diverToLogBook(alice), logBook);
        assertEq(registry.totalDivers(), 1);
    }

    function test_registerDiver_emitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit DiveLogRegistry.DiverRegistered(alice, address(0), 0);
        vm.prank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);
    }

    function test_registerDiver_multipleDivers() public {
        vm.prank(alice);
        address logBookA = registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);

        vm.prank(bob);
        address logBookB = registry.registerDiver("Bob Jones", 35, 72, 190, true, UnitSystem.Metric);

        assertTrue(registry.isRegistered(alice));
        assertTrue(registry.isRegistered(bob));
        assertEq(registry.totalDivers(), 2);
        assertNotEq(logBookA, logBookB);
    }

    function test_revert_registerTwice() public {
        vm.startPrank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);
        vm.expectRevert(DiveLogRegistry.AlreadyRegistered.selector);
        registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);
        vm.stopPrank();
    }

    function test_revert_emptyName() public {
        vm.prank(alice);
        vm.expectRevert(DiveLogRegistry.EmptyName.selector);
        registry.registerDiver("", 30, 65, 140, false, UnitSystem.Imperial);
    }

    function test_getMyLogBook() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);

        vm.prank(alice);
        address fetched = registry.getMyLogBook();
        assertEq(fetched, logBook);
    }

    function test_revert_getMyLogBook_notRegistered() public {
        vm.prank(alice);
        vm.expectRevert(DiveLogRegistry.NotRegistered.selector);
        registry.getMyLogBook();
    }

    function test_getLogBook() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);

        address fetched = registry.getLogBook(alice);
        assertEq(fetched, logBook);
    }

    function test_revert_getLogBook_notRegistered() public {
        vm.expectRevert(DiveLogRegistry.NotRegistered.selector);
        registry.getLogBook(alice);
    }

    function test_getAllLogBooks() public {
        vm.prank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);
        vm.prank(bob);
        registry.registerDiver("Bob Jones", 35, 72, 190, true, UnitSystem.Metric);

        address[] memory books = registry.getAllLogBooks();
        assertEq(books.length, 2);
    }

    function test_getLogBookPage() public {
        address[5] memory divers;
        for (uint256 i; i < 5; i++) {
            divers[i] = makeAddr(string(abi.encodePacked("diver", vm.toString(i))));
            vm.prank(divers[i]);
            registry.registerDiver("Test Diver", 30, 70, 170, true, UnitSystem.Imperial);
        }

        address[] memory page = registry.getLogBookPage(1, 2);
        assertEq(page.length, 2);
        assertEq(page[0], registry.diverToLogBook(divers[1]));
        assertEq(page[1], registry.diverToLogBook(divers[2]));
    }

    function test_getLogBookPage_offsetBeyondEnd() public {
        vm.prank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);

        address[] memory page = registry.getLogBookPage(10, 5);
        assertEq(page.length, 0);
    }

    function test_getLogBookPage_partialPage() public {
        vm.prank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);
        vm.prank(bob);
        registry.registerDiver("Bob Jones", 35, 72, 190, true, UnitSystem.Metric);

        address[] memory page = registry.getLogBookPage(1, 10);
        assertEq(page.length, 1);
    }

    function test_logBookOwner() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);

        DiveLogBook book = DiveLogBook(payable(logBook));
        assertEq(book.owner(), alice);
    }

    function test_logBookProfile() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, false, UnitSystem.Imperial);

        DiveLogBook book = DiveLogBook(payable(logBook));
        (string memory name, uint8 age, uint16 height, uint16 weight, bool isMale, UnitSystem units) = book.profile();
        assertEq(name, "Alice Smith");
        assertEq(age, 30);
        assertEq(height, 65);
        assertEq(weight, 140);
        assertFalse(isMale);
        assertEq(uint256(units), uint256(UnitSystem.Imperial));
    }
}
