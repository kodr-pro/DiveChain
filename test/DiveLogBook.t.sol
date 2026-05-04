// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DiveLogRegistry} from "../src/DiveLogRegistry.sol";
import {DiveLogBook, UnitSystem, DiveMode, BreathingGas, DivePurpose, SuitType, DecompressionType, DiveData, Environment, Decompression, GasData, DiverProfile, DiveLog} from "../src/DiveLogBook.sol";

contract DiveLogBookTest is Test {
    DiveLogRegistry public registry;
    DiveLogBook public logBook;
    address public owner = makeAddr("owner");
    address public stranger = makeAddr("stranger");

    uint64 constant DIVE_DATE = 1714521600;

    function setUp() public {
        registry = new DiveLogRegistry();
        vm.prank(owner);
        address lb = registry.registerDiver("Test Diver", 30, 72, 185, true, UnitSystem.Imperial);
        logBook = DiveLogBook(payable(lb));
    }

    function _makeDiveData() internal pure returns (DiveData memory) {
        return DiveData({
            leaveSurfaceTime: 1714521600,
            leaveBottomTime: 1714522440,
            reachSurfaceTime: 1714522700,
            bottomTimeMinutes: 14,
            maxDepth: 95,
            averageDepth: 75,
            mode: DiveMode.SSA,
            purpose: DivePurpose.Inspection,
            suit: SuitType.Dry
        });
    }

    function _makeEnvironment() internal pure returns (Environment memory) {
        return Environment({
            airTemp: 72,
            waterTemp: 58,
            currentKnots: 1,
            location: "Naval Station Norfolk, Pier 3",
            bottomType: "Mud/Silt",
            weatherConditions: "Clear"
        });
    }

    function _makeDecompression() internal pure returns (Decompression memory) {
        return Decompression({
            decompType: DecompressionType.Standard,
            totalDecompTimeMinutes: 6,
            maxDepthAttained: 95,
            tableSchedule: bytes32("USN 9-7"),
            repetitiveGroup: bytes1("D"),
            surfaceIntervalMinutes: 0,
            newRepetitiveGroup: bytes1(0)
        });
    }

    function _makeGasData() internal pure returns (GasData memory) {
        return GasData({
            gasType: BreathingGas.Air,
            o2Percent: 21,
            hePercent: 0,
            n2Percent: 79,
            airInPsi: 3000,
            airOutPsi: 1200,
            airUsedPsi: 1800,
            bailoutPressure: 2800
        });
    }

    function test_logDive() public {
        vm.prank(owner);
        uint256 diveId = logBook.logDive(
            DIVE_DATE,
            UnitSystem.Imperial,
            _makeDiveData(),
            _makeEnvironment(),
            _makeDecompression(),
            _makeGasData(),
            "Hull inspection, starboard side."
        );

        assertEq(diveId, 1);
        assertEq(logBook.diveCount(), 1);
    }

    function test_logDive_emitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit DiveLogBook.DiveLogged(1, DIVE_DATE);
        logBook.logDive(
            DIVE_DATE,
            UnitSystem.Imperial,
            _makeDiveData(),
            _makeEnvironment(),
            _makeDecompression(),
            _makeGasData(),
            "Test"
        );
    }

    function test_logDive_sequentialIds() public {
        vm.startPrank(owner);
        for (uint256 i; i < 5; i++) {
            uint256 id = logBook.logDive(
                DIVE_DATE + uint64(i * 86400),
                UnitSystem.Imperial,
                _makeDiveData(),
                _makeEnvironment(),
                _makeDecompression(),
                _makeGasData(),
                "Test dive"
            );
            assertEq(id, i + 1);
        }
        vm.stopPrank();
        assertEq(logBook.diveCount(), 5);
    }

    function test_revert_logDive_notOwner() public {
        vm.prank(stranger);
        vm.expectRevert(DiveLogBook.NotOwner.selector);
        logBook.logDive(
            DIVE_DATE,
            UnitSystem.Imperial,
            _makeDiveData(),
            _makeEnvironment(),
            _makeDecompression(),
            _makeGasData(),
            "Unauthorized"
        );
    }

    function test_revert_zeroDepth() public {
        DiveData memory data = _makeDiveData();
        data.maxDepth = 0;
        vm.prank(owner);
        vm.expectRevert(DiveLogBook.InvalidDepth.selector);
        logBook.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "Bad");
    }

    function test_revert_negativeDepth() public {
        DiveData memory data = _makeDiveData();
        data.maxDepth = -10;
        vm.prank(owner);
        vm.expectRevert(DiveLogBook.InvalidDepth.selector);
        logBook.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "Bad");
    }

    function test_revert_zeroBottomTime() public {
        DiveData memory data = _makeDiveData();
        data.bottomTimeMinutes = 0;
        vm.prank(owner);
        vm.expectRevert(DiveLogBook.InvalidTimes.selector);
        logBook.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "Bad");
    }

    function test_getDive() public {
        vm.prank(owner);
        logBook.logDive(
            DIVE_DATE,
            UnitSystem.Metric,
            _makeDiveData(),
            _makeEnvironment(),
            _makeDecompression(),
            _makeGasData(),
            "Test remarks"
        );

        DiveLog memory dive = logBook.getDive(1);
        assertEq(dive.id, 1);
        assertEq(dive.diveDate, DIVE_DATE);
        assertEq(uint256(dive.units), uint256(UnitSystem.Metric));
        assertEq(dive.data.maxDepth, 95);
        assertEq(dive.data.bottomTimeMinutes, 14);
        assertEq(uint256(dive.data.mode), uint256(DiveMode.SSA));
        assertEq(uint256(dive.data.purpose), uint256(DivePurpose.Inspection));
        assertEq(uint256(dive.data.suit), uint256(SuitType.Dry));
        assertEq(dive.env.airTemp, 72);
        assertEq(dive.env.waterTemp, 58);
        assertEq(dive.env.currentKnots, 1);
        assertEq(dive.env.location, "Naval Station Norfolk, Pier 3");
        assertEq(dive.env.bottomType, "Mud/Silt");
        assertEq(dive.env.weatherConditions, "Clear");
        assertEq(uint256(dive.decomp.decompType), uint256(DecompressionType.Standard));
        assertEq(dive.decomp.totalDecompTimeMinutes, 6);
        assertEq(dive.decomp.repetitiveGroup, bytes1("D"));
        assertEq(uint256(dive.gas.gasType), uint256(BreathingGas.Air));
        assertEq(dive.gas.o2Percent, 21);
        assertEq(dive.gas.n2Percent, 79);
        assertEq(dive.gas.airInPsi, 3000);
        assertEq(dive.gas.airOutPsi, 1200);
        assertEq(dive.gas.airUsedPsi, 1800);
        assertEq(dive.remarks, "Test remarks");
    }

    function test_revert_getDive_notFound() public {
        vm.expectRevert(abi.encodeWithSelector(DiveLogBook.DiveNotFound.selector, uint256(1)));
        logBook.getDive(1);
    }

    function test_revert_getDive_zeroId() public {
        vm.expectRevert(abi.encodeWithSelector(DiveLogBook.DiveNotFound.selector, uint256(0)));
        logBook.getDive(0);
    }

    function test_getDivesByDate() public {
        vm.startPrank(owner);
        logBook.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 1");
        logBook.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 2");
        logBook.logDive(DIVE_DATE + 86400, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 3");
        vm.stopPrank();

        uint256[] memory sameDay = logBook.getDivesByDate(DIVE_DATE);
        assertEq(sameDay.length, 2);
        assertEq(sameDay[0], 1);
        assertEq(sameDay[1], 2);

        uint256[] memory nextDay = logBook.getDivesByDate(DIVE_DATE + 86400);
        assertEq(nextDay.length, 1);
        assertEq(nextDay[0], 3);

        uint256[] memory empty = logBook.getDivesByDate(9999999999);
        assertEq(empty.length, 0);
    }

    function test_getMultipleDives() public {
        vm.startPrank(owner);
        logBook.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 1");
        logBook.logDive(DIVE_DATE + 86400, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 2");
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        DiveLog[] memory dives = logBook.getMultipleDives(ids);
        assertEq(dives.length, 2);
        assertEq(dives[0].id, 1);
        assertEq(dives[1].id, 2);
    }

    function test_getAllDiveIds() public {
        vm.startPrank(owner);
        for (uint256 i; i < 3; i++) {
            logBook.logDive(DIVE_DATE + uint64(i * 86400), UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "");
        }
        vm.stopPrank();

        uint256[] memory ids = logBook.getAllDiveIds();
        assertEq(ids.length, 3);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);
        assertEq(ids[2], 3);
    }

    function test_batchLogDives() public {
        uint64[3] memory dates = [DIVE_DATE, DIVE_DATE + 86400, DIVE_DATE + 172800];
        uint64[] memory diveDates = new uint64[](3);
        UnitSystem[] memory units = new UnitSystem[](3);
        DiveData[] memory dataArr = new DiveData[](3);
        Environment[] memory envArr = new Environment[](3);
        Decompression[] memory decompArr = new Decompression[](3);
        GasData[] memory gasArr = new GasData[](3);
        string[] memory remarksArr = new string[](3);

        for (uint256 i; i < 3; i++) {
            diveDates[i] = dates[i];
            units[i] = UnitSystem.Imperial;
            dataArr[i] = _makeDiveData();
            envArr[i] = _makeEnvironment();
            decompArr[i] = _makeDecompression();
            gasArr[i] = _makeGasData();
            remarksArr[i] = "Batch dive";
        }

        vm.prank(owner);
        uint256[] memory ids = logBook.batchLogDives(diveDates, units, dataArr, envArr, decompArr, gasArr, remarksArr);

        assertEq(ids.length, 3);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);
        assertEq(ids[2], 3);
        assertEq(logBook.diveCount(), 3);
    }

    function test_batchLogDives_revert_badDepth() public {
        uint64[] memory diveDates = new uint64[](2);
        UnitSystem[] memory units = new UnitSystem[](2);
        DiveData[] memory dataArr = new DiveData[](2);
        Environment[] memory envArr = new Environment[](2);
        Decompression[] memory decompArr = new Decompression[](2);
        GasData[] memory gasArr = new GasData[](2);
        string[] memory remarksArr = new string[](2);

        for (uint256 i; i < 2; i++) {
            diveDates[i] = DIVE_DATE;
            units[i] = UnitSystem.Imperial;
            dataArr[i] = _makeDiveData();
            envArr[i] = _makeEnvironment();
            decompArr[i] = _makeDecompression();
            gasArr[i] = _makeGasData();
            remarksArr[i] = "Batch";
        }
        dataArr[1].maxDepth = 0;

        vm.prank(owner);
        vm.expectRevert(DiveLogBook.InvalidDepth.selector);
        logBook.batchLogDives(diveDates, units, dataArr, envArr, decompArr, gasArr, remarksArr);
    }

    function test_batchLogDives_revert_notOwner() public {
        uint64[] memory diveDates = new uint64[](1);
        UnitSystem[] memory units = new UnitSystem[](1);
        DiveData[] memory dataArr = new DiveData[](1);
        Environment[] memory envArr = new Environment[](1);
        Decompression[] memory decompArr = new Decompression[](1);
        GasData[] memory gasArr = new GasData[](1);
        string[] memory remarksArr = new string[](1);

        diveDates[0] = DIVE_DATE;
        units[0] = UnitSystem.Imperial;
        dataArr[0] = _makeDiveData();
        envArr[0] = _makeEnvironment();
        decompArr[0] = _makeDecompression();
        gasArr[0] = _makeGasData();
        remarksArr[0] = "Unauthorized";

        vm.prank(stranger);
        vm.expectRevert(DiveLogBook.NotOwner.selector);
        logBook.batchLogDives(diveDates, units, dataArr, envArr, decompArr, gasArr, remarksArr);
    }

    function test_updateProfile() public {
        vm.prank(owner);
        logBook.updateProfile("Updated Name", 31, 73, 190, true, UnitSystem.Metric);

        (string memory name, uint8 age, uint16 height, uint16 weight, bool isMale, UnitSystem units) = logBook.profile();
        assertEq(name, "Updated Name");
        assertEq(age, 31);
        assertEq(height, 73);
        assertEq(weight, 190);
        assertTrue(isMale);
        assertEq(uint256(units), uint256(UnitSystem.Metric));
    }

    function test_revert_updateProfile_notOwner() public {
        vm.prank(stranger);
        vm.expectRevert(DiveLogBook.NotOwner.selector);
        logBook.updateProfile("Hacker", 99, 99, 99, true, UnitSystem.Imperial);
    }

    function test_metricDive() public {
        DiveData memory data = _makeDiveData();
        data.maxDepth = 30; // 30 meters

        Environment memory env = _makeEnvironment();
        env.airTemp = 22;
        env.waterTemp = 16;

        GasData memory gas = _makeGasData();
        gas.airInPsi = 2900;
        gas.gasType = BreathingGas.Nitrox;
        gas.o2Percent = 32;
        gas.n2Percent = 68;
        gas.hePercent = 0;

        vm.prank(owner);
        uint256 id = logBook.logDive(DIVE_DATE, UnitSystem.Metric, data, env, _makeDecompression(), gas, "Metric nitrox dive");

        DiveLog memory dive = logBook.getDive(id);
        assertEq(uint256(dive.units), uint256(UnitSystem.Metric));
        assertEq(dive.data.maxDepth, 30);
        assertEq(uint256(dive.gas.gasType), uint256(BreathingGas.Nitrox));
        assertEq(dive.gas.o2Percent, 32);
    }

    function test_allDivePurposes() public {
        DivePurpose[13] memory purposes = [
            DivePurpose.Training,
            DivePurpose.Inspection,
            DivePurpose.Repair,
            DivePurpose.Search,
            DivePurpose.Salvage,
            DivePurpose.Recovery,
            DivePurpose.Construction,
            DivePurpose.Research,
            DivePurpose.EOD,
            DivePurpose.Security,
            DivePurpose.Photographic,
            DivePurpose.Recreational,
            DivePurpose.Other
        ];

        vm.startPrank(owner);
        for (uint256 i; i < 13; i++) {
            DiveData memory data = _makeDiveData();
            data.purpose = purposes[i];
            logBook.logDive(DIVE_DATE + uint64(i * 86400), UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "");
        }
        vm.stopPrank();

        assertEq(logBook.diveCount(), 13);
    }

    function test_allDecompressionTypes() public {
        DecompressionType[7] memory types = [
            DecompressionType.NoneDecomp,
            DecompressionType.Standard,
            DecompressionType.SurfaceDecompO2,
            DecompressionType.SurfaceDecompAir,
            DecompressionType.Saturation,
            DecompressionType.Repetitive,
            DecompressionType.ExceptionalExposure
        ];

        vm.startPrank(owner);
        for (uint256 i; i < 7; i++) {
            Decompression memory decomp = _makeDecompression();
            decomp.decompType = types[i];
            logBook.logDive(DIVE_DATE + uint64(i * 86400), UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), decomp, _makeGasData(), "");
        }
        vm.stopPrank();

        assertEq(logBook.diveCount(), 7);
    }

    function test_allBreathingGases() public {
        BreathingGas[6] memory gases = [
            BreathingGas.Air,
            BreathingGas.Nitrox,
            BreathingGas.Heliox,
            BreathingGas.Trimix,
            BreathingGas.Oxygen,
            BreathingGas.Mixed
        ];

        vm.startPrank(owner);
        for (uint256 i; i < 6; i++) {
            GasData memory gas = _makeGasData();
            gas.gasType = gases[i];
            logBook.logDive(DIVE_DATE + uint64(i * 86400), UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), gas, "");
        }
        vm.stopPrank();

        assertEq(logBook.diveCount(), 6);
    }

    function test_allSuitTypes() public {
        SuitType[4] memory suits = [SuitType.Wet, SuitType.Dry, SuitType.HotWater, SuitType.Swim];

        vm.startPrank(owner);
        for (uint256 i; i < 4; i++) {
            DiveData memory data = _makeDiveData();
            data.suit = suits[i];
            logBook.logDive(DIVE_DATE + uint64(i * 86400), UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "");
        }
        vm.stopPrank();

        assertEq(logBook.diveCount(), 4);
    }

    function test_getDiveCount_initial() public view {
        assertEq(logBook.getDiveCount(), 0);
    }

    function test_diveData_integrity() public {
        DiveData memory data = _makeDiveData();
        data.leaveSurfaceTime = 1000;
        data.leaveBottomTime = 2000;
        data.reachSurfaceTime = 3000;
        data.bottomTimeMinutes = 16;
        data.maxDepth = 130;
        data.averageDepth = 100;
        data.mode = DiveMode.SCUBA;
        data.purpose = DivePurpose.Recreational;
        data.suit = SuitType.Wet;

        vm.prank(owner);
        uint256 id = logBook.logDive(
            DIVE_DATE,
            UnitSystem.Imperial,
            data,
            _makeEnvironment(),
            _makeDecompression(),
            _makeGasData(),
            "Integrity test"
        );

        DiveLog memory dive = logBook.getDive(id);
        assertEq(dive.data.leaveSurfaceTime, 1000);
        assertEq(dive.data.leaveBottomTime, 2000);
        assertEq(dive.data.reachSurfaceTime, 3000);
        assertEq(dive.data.bottomTimeMinutes, 16);
        assertEq(dive.data.maxDepth, 130);
        assertEq(dive.data.averageDepth, 100);
        assertEq(uint256(dive.data.mode), uint256(DiveMode.SCUBA));
        assertEq(uint256(dive.data.purpose), uint256(DivePurpose.Recreational));
        assertEq(uint256(dive.data.suit), uint256(SuitType.Wet));
    }
}
