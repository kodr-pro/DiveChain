// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DiveLogRegistry} from "../src/DiveLogRegistry.sol";
import {UnitSystem, BiologicalSex, DiverProfile} from "../src/interfaces/IDiveLogTypes.sol";
import {DiveLogBook} from "../src/DiveLogBook.sol";
import {IDiveLogRegistry} from "../src/interfaces/IDiveLogRegistry.sol";
import {IERC165} from "../src/interfaces/IERC165.sol";

contract DiveLogRegistryTest is Test {
    DiveLogRegistry public registry;
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    function setUp() public {
        registry = new DiveLogRegistry();
    }

    function test_registerDiver() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);

        assertTrue(registry.isRegistered(alice));
        assertEq(registry.diverToLogBook(alice), logBook);
        assertEq(registry.totalDivers(), 1);
    }

    function test_registerDiver_emitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit IDiveLogRegistry.DiverRegistered(alice, address(0), 0);
        vm.prank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);
    }

    function test_registerDiver_multipleDivers() public {
        vm.prank(alice);
        address logBookA = registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);

        vm.prank(bob);
        address logBookB = registry.registerDiver("Bob Jones", 35, 72, 190, BiologicalSex.Male, UnitSystem.Metric);

        assertTrue(registry.isRegistered(alice));
        assertTrue(registry.isRegistered(bob));
        assertEq(registry.totalDivers(), 2);
        assertNotEq(logBookA, logBookB);
    }

    function test_revert_registerTwice() public {
        vm.startPrank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);
        vm.expectRevert(IDiveLogRegistry.AlreadyRegistered.selector);
        registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);
        vm.stopPrank();
    }

    function test_revert_emptyName() public {
        vm.prank(alice);
        vm.expectRevert(IDiveLogRegistry.EmptyName.selector);
        registry.registerDiver("", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);
    }

    function test_getMyLogBook() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);

        vm.prank(alice);
        address fetched = registry.getMyLogBook();
        assertEq(fetched, logBook);
    }

    function test_revert_getMyLogBook_notRegistered() public {
        vm.prank(alice);
        vm.expectRevert(IDiveLogRegistry.NotRegistered.selector);
        registry.getMyLogBook();
    }

    function test_getLogBook() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);

        address fetched = registry.getLogBook(alice);
        assertEq(fetched, logBook);
    }

    function test_revert_getLogBook_notRegistered() public {
        vm.expectRevert(IDiveLogRegistry.NotRegistered.selector);
        registry.getLogBook(alice);
    }

    function test_getAllLogBooks() public {
        vm.prank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);
        vm.prank(bob);
        registry.registerDiver("Bob Jones", 35, 72, 190, BiologicalSex.Male, UnitSystem.Metric);

        address[] memory books = registry.getAllLogBooks();
        assertEq(books.length, 2);
    }

    function test_getLogBookPage() public {
        address[5] memory divers;
        for (uint256 i; i < 5; i++) {
            divers[i] = makeAddr(string(abi.encodePacked("diver", vm.toString(i))));
            vm.prank(divers[i]);
            registry.registerDiver("Test Diver", 30, 70, 170, BiologicalSex.Male, UnitSystem.Imperial);
        }

        address[] memory page = registry.getLogBookPage(1, 2);
        assertEq(page.length, 2);
        assertEq(page[0], registry.diverToLogBook(divers[1]));
        assertEq(page[1], registry.diverToLogBook(divers[2]));
    }

    function test_getLogBookPage_offsetBeyondEnd() public {
        vm.prank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);

        address[] memory page = registry.getLogBookPage(10, 5);
        assertEq(page.length, 0);
    }

    function test_getLogBookPage_partialPage() public {
        vm.prank(alice);
        registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);
        vm.prank(bob);
        registry.registerDiver("Bob Jones", 35, 72, 190, BiologicalSex.Male, UnitSystem.Metric);

        address[] memory page = registry.getLogBookPage(1, 10);
        assertEq(page.length, 1);
    }

    function test_logBookOwner() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);

        DiveLogBook book = DiveLogBook(payable(logBook));
        assertEq(book.owner(), alice);
    }

    function test_logBookProfile() public {
        vm.prank(alice);
        address logBook = registry.registerDiver("Alice Smith", 30, 65, 140, BiologicalSex.Female, UnitSystem.Imperial);

        DiveLogBook book = DiveLogBook(payable(logBook));
        DiverProfile memory p = book.profile();
        assertEq(p.name, "Alice Smith");
        assertEq(p.age, 30);
        assertEq(p.height, 65);
        assertEq(p.weight, 140);
        assertEq(uint256(p.sex), uint256(BiologicalSex.Female));
        assertEq(uint256(p.units), uint256(UnitSystem.Imperial));
    }

    function test_supportsInterface() public {
        assertTrue(registry.supportsInterface(type(IERC165).interfaceId));
        assertTrue(registry.supportsInterface(type(IDiveLogRegistry).interfaceId));
        assertFalse(registry.supportsInterface(0xffffffff));
    }

    function test_totalDivers_incremental() public {
        for (uint256 i; i < 5; i++) {
            address diver = makeAddr(string(abi.encodePacked("diver", vm.toString(i))));
            vm.prank(diver);
            registry.registerDiver("Test", 25, 70, 170, BiologicalSex.Male, UnitSystem.Imperial);
            assertEq(registry.totalDivers(), i + 1);
        }
    }
}
