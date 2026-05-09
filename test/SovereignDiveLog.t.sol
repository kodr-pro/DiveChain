// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {SovereignDiveLog} from "../src/SovereignDiveLog.sol";
import {UnitSystem, DiveMode, BreathingGas, DivePurpose, SuitType, DecompressionType, BiologicalSex, DiveData, Environment, Decompression, GasData, DiverProfile, DiveLog, VoidInfo, Attestation} from "../src/interfaces/IDiveLogTypes.sol";
import {IDiveLog} from "../src/interfaces/IDiveLog.sol";
import {IERC165} from "../src/interfaces/IERC165.sol";
import {DiveLogTypedData} from "../src/interfaces/IDiveLogTypedData.sol";

contract SovereignDiveLogTest is Test {
    SovereignDiveLog public diveLog;
    address public owner = makeAddr("owner");
    address public stranger = makeAddr("stranger");
    address public buddy = makeAddr("buddy");
    uint256 public buddyPk;

    uint64 constant DIVE_DATE = 1714521600;

    function setUp() public {
        (buddy, buddyPk) = makeAddrAndKey("buddy");
        vm.prank(owner);
        diveLog = new SovereignDiveLog(
            owner,
            "Test Diver",
            30,
            72,
            185,
            BiologicalSex.Male,
            UnitSystem.Imperial
        );
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
            cylinderPressureIn: 3000,
            cylinderPressureOut: 1200,
            gasConsumed: 1800,
            bailoutPressure: 2800
        });
    }

    function _logDive() internal returns (uint256) {
        vm.prank(owner);
        return diveLog.logDive(
            DIVE_DATE,
            UnitSystem.Imperial,
            _makeDiveData(),
            _makeEnvironment(),
            _makeDecompression(),
            _makeGasData(),
            "Hull inspection, starboard side."
        );
    }

    // ===== Constructor =====

    function test_constructor() public view {
        assertEq(diveLog.owner(), owner);
        DiverProfile memory p = diveLog.profile();
        assertEq(p.name, "Test Diver");
        assertEq(p.age, 30);
        assertEq(p.height, 72);
        assertEq(p.weight, 185);
        assertEq(uint256(p.sex), uint256(BiologicalSex.Male));
        assertEq(uint256(p.units), uint256(UnitSystem.Imperial));
    }

    // ===== logDive =====

    function test_logDive() public {
        uint256 diveId = _logDive();
        assertEq(diveId, 1);
        assertEq(diveLog.diveCount(), 1);
    }

    function test_logDive_emitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, false, true);
        emit IDiveLog.DiveLogged(1, DIVE_DATE);
        diveLog.logDive(
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
            uint256 id = diveLog.logDive(
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
        assertEq(diveLog.diveCount(), 5);
    }

    function test_revert_logDive_notOwner() public {
        vm.prank(stranger);
        vm.expectRevert(IDiveLog.NotOwner.selector);
        diveLog.logDive(
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
        vm.expectRevert(IDiveLog.InvalidDepth.selector);
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "Bad");
    }

    function test_revert_negativeDepth() public {
        DiveData memory data = _makeDiveData();
        data.maxDepth = -10;
        vm.prank(owner);
        vm.expectRevert(IDiveLog.InvalidDepth.selector);
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "Bad");
    }

    function test_revert_zeroBottomTime() public {
        DiveData memory data = _makeDiveData();
        data.bottomTimeMinutes = 0;
        vm.prank(owner);
        vm.expectRevert(IDiveLog.InvalidTimes.selector);
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "Bad");
    }

    // ===== getDive =====

    function test_getDive() public {
        _logDive();
        DiveLog memory dive = diveLog.getDive(1);
        assertEq(dive.id, 1);
        assertEq(dive.diveDate, DIVE_DATE);
        assertEq(dive.data.maxDepth, 95);
        assertEq(dive.data.bottomTimeMinutes, 14);
        assertEq(dive.remarks, "Hull inspection, starboard side.");
    }

    function test_revert_getDive_notFound() public {
        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveNotFound.selector, uint256(1)));
        diveLog.getDive(1);
    }

    function test_revert_getDive_zeroId() public {
        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveNotFound.selector, uint256(0)));
        diveLog.getDive(0);
    }

    // ===== getDivesByDate =====

    function test_getDivesByDate() public {
        vm.startPrank(owner);
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 1");
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 2");
        diveLog.logDive(DIVE_DATE + 86400, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 3");
        vm.stopPrank();

        uint256[] memory sameDay = diveLog.getDivesByDate(DIVE_DATE);
        assertEq(sameDay.length, 2);
        assertEq(sameDay[0], 1);
        assertEq(sameDay[1], 2);

        uint256[] memory nextDay = diveLog.getDivesByDate(DIVE_DATE + 86400);
        assertEq(nextDay.length, 1);
        assertEq(nextDay[0], 3);
    }

    // ===== getMultipleDives =====

    function test_getMultipleDives() public {
        vm.startPrank(owner);
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 1");
        diveLog.logDive(DIVE_DATE + 86400, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Dive 2");
        vm.stopPrank();

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        DiveLog[] memory dives = diveLog.getMultipleDives(ids);
        assertEq(dives.length, 2);
        assertEq(dives[0].id, 1);
        assertEq(dives[1].id, 2);
    }

    function test_revert_getMultipleDives_invalidId() public {
        _logDive();
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 99;

        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveNotFound.selector, uint256(99)));
        diveLog.getMultipleDives(ids);
    }

    // ===== getAllDiveIds =====

    function test_getAllDiveIds() public {
        vm.startPrank(owner);
        for (uint256 i; i < 3; i++) {
            diveLog.logDive(DIVE_DATE + uint64(i * 86400), UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "");
        }
        vm.stopPrank();

        uint256[] memory ids = diveLog.getAllDiveIds();
        assertEq(ids.length, 3);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);
        assertEq(ids[2], 3);
    }

    // ===== batchLogDives =====

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
        uint256[] memory ids = diveLog.batchLogDives(diveDates, units, dataArr, envArr, decompArr, gasArr, remarksArr);

        assertEq(ids.length, 3);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);
        assertEq(ids[2], 3);
        assertEq(diveLog.diveCount(), 3);
    }

    function test_batchLogDives_revert_arrayLengthMismatch() public {
        uint64[] memory diveDates = new uint64[](2);
        UnitSystem[] memory units = new UnitSystem[](1);
        DiveData[] memory dataArr = new DiveData[](2);
        Environment[] memory envArr = new Environment[](2);
        Decompression[] memory decompArr = new Decompression[](2);
        GasData[] memory gasArr = new GasData[](2);
        string[] memory remarksArr = new string[](2);

        for (uint256 i; i < 2; i++) {
            diveDates[i] = DIVE_DATE;
            dataArr[i] = _makeDiveData();
            envArr[i] = _makeEnvironment();
            decompArr[i] = _makeDecompression();
            gasArr[i] = _makeGasData();
            remarksArr[i] = "Batch";
        }
        units[0] = UnitSystem.Imperial;

        vm.prank(owner);
        vm.expectRevert(IDiveLog.ArrayLengthMismatch.selector);
        diveLog.batchLogDives(diveDates, units, dataArr, envArr, decompArr, gasArr, remarksArr);
    }

    // ===== voidDive =====

    function test_voidDive() public {
        _logDive();

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit IDiveLog.DiveVoided(1, 0, owner, "Incorrect depth");
        diveLog.voidDive(1, 0, "Incorrect depth");
    }

    function test_voidDive_withSupersede() public {
        vm.startPrank(owner);
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "Bad dive");

        DiveData memory correctedData = _makeDiveData();
        correctedData.maxDepth = 100;
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, correctedData, _makeEnvironment(), _makeDecompression(), _makeGasData(), "Corrected dive");

        diveLog.voidDive(1, 2, "Depth was recorded incorrectly");
        vm.stopPrank();

        assertTrue(diveLog.isDiveVoided(1));
        assertFalse(diveLog.isDiveVoided(2));

        VoidInfo memory info = diveLog.getVoidInfo(1);
        assertTrue(info.isVoided);
        assertEq(info.supersededById, 2);
        assertEq(info.voidedBy, owner);
        assertEq(info.reason, "Depth was recorded incorrectly");
    }

    function test_voidDive_voidOnly() public {
        _logDive();

        vm.prank(owner);
        diveLog.voidDive(1, 0, "Duplicate entry");

        VoidInfo memory info = diveLog.getVoidInfo(1);
        assertTrue(info.isVoided);
        assertEq(info.supersededById, 0);
        assertEq(info.reason, "Duplicate entry");
    }

    function test_revert_voidDive_alreadyVoided() public {
        _logDive();

        vm.startPrank(owner);
        diveLog.voidDive(1, 0, "First void");
        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveAlreadyVoided.selector, uint256(1)));
        diveLog.voidDive(1, 0, "Second void attempt");
        vm.stopPrank();
    }

    function test_revert_voidDive_notOwner() public {
        _logDive();

        vm.prank(stranger);
        vm.expectRevert(IDiveLog.NotOwner.selector);
        diveLog.voidDive(1, 0, "Unauthorized");
    }

    function test_revert_voidDive_notFound() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveNotFound.selector, uint256(99)));
        diveLog.voidDive(99, 0, "No dive");
    }

    function test_revert_voidDive_selfSupersede() public {
        _logDive();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IDiveLog.InvalidSupersede.selector, uint256(1), uint256(1)));
        diveLog.voidDive(1, 1, "Cannot supersede self");
    }

    function test_revert_voidDive_invalidSupersede() public {
        _logDive();

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IDiveLog.InvalidSupersede.selector, uint256(1), uint256(99)));
        diveLog.voidDive(1, 99, "Nonexistent supersede");
    }

    function test_voidDive_chain() public {
        vm.startPrank(owner);
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "V1");
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "V2");
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, _makeDiveData(), _makeEnvironment(), _makeDecompression(), _makeGasData(), "V3");

        diveLog.voidDive(1, 2, "Superseded by V2");
        diveLog.voidDive(2, 3, "Superseded by V3");
        vm.stopPrank();

        VoidInfo memory v1 = diveLog.getVoidInfo(1);
        assertEq(v1.supersededById, 2);

        VoidInfo memory v2 = diveLog.getVoidInfo(2);
        assertEq(v2.supersededById, 3);

        assertFalse(diveLog.isDiveVoided(3));
    }

    // ===== attestDive =====

    function test_attestDive() public {
        _logDive();

        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, false, true);
        emit IDiveLog.DiveAttested(1, buddy);
        diveLog.attestDive(1, signature);

        Attestation[] memory attestations = diveLog.getAttestations(1);
        assertEq(attestations.length, 1);
        assertEq(attestations[0].attester, buddy);
        assertGt(attestations[0].attestedAt, 0);
    }

    function test_attestDive_multipleAttestations() public {
        _logDive();

        (address buddy2, uint256 buddy2Pk) = makeAddrAndKey("buddy2");

        bytes32 digest1 = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(buddyPk, digest1);
        bytes memory sig1 = abi.encodePacked(r1, s1, v1);

        bytes32 digest2 = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(buddy2Pk, digest2);
        bytes memory sig2 = abi.encodePacked(r2, s2, v2);

        diveLog.attestDive(1, sig1);
        diveLog.attestDive(1, sig2);

        Attestation[] memory attestations = diveLog.getAttestations(1);
        assertEq(attestations.length, 2);
        assertEq(attestations[0].attester, buddy);
        assertEq(attestations[1].attester, buddy2);
    }

    function test_revert_attestDive_alreadyAttested() public {
        _logDive();

        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        diveLog.attestDive(1, signature);

        vm.expectRevert(abi.encodeWithSelector(IDiveLog.AlreadyAttested.selector, uint256(1), buddy));
        diveLog.attestDive(1, signature);
    }

    function test_revert_attestDive_invalidSignature() public {
        _logDive();

        bytes memory badSignature = new bytes(65);
        vm.expectRevert(IDiveLog.InvalidSignature.selector);
        diveLog.attestDive(1, badSignature);
    }

    function test_revert_attestDive_wrongLength() public {
        _logDive();

        bytes memory shortSig = new bytes(64);
        vm.expectRevert(IDiveLog.InvalidSignature.selector);
        diveLog.attestDive(1, shortSig);
    }

    function test_revert_attestDive_notFound() public {
        bytes memory signature = new bytes(65);
        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveNotFound.selector, uint256(99)));
        diveLog.attestDive(99, signature);
    }

    function test_revert_attestDive_voidedDive() public {
        _logDive();

        vm.prank(owner);
        diveLog.voidDive(1, 0, "Voided");

        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveAlreadyVoided.selector, uint256(1)));
        diveLog.attestDive(1, signature);
    }

    function test_attestDive_anyoneCanSubmit() public {
        _logDive();

        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(stranger);
        diveLog.attestDive(1, signature);

        Attestation[] memory attestations = diveLog.getAttestations(1);
        assertEq(attestations.length, 1);
        assertEq(attestations[0].attester, buddy);
    }

    // ===== profile =====

    function test_updateProfile() public {
        vm.prank(owner);
        diveLog.updateProfile("Updated Name", 31, 73, 190, BiologicalSex.Male, UnitSystem.Metric);

        DiverProfile memory p = diveLog.profile();
        assertEq(p.name, "Updated Name");
        assertEq(p.age, 31);
        assertEq(p.height, 73);
        assertEq(p.weight, 190);
        assertEq(uint256(p.sex), uint256(BiologicalSex.Male));
        assertEq(uint256(p.units), uint256(UnitSystem.Metric));
    }

    function test_revert_updateProfile_notOwner() public {
        vm.prank(stranger);
        vm.expectRevert(IDiveLog.NotOwner.selector);
        diveLog.updateProfile("Hacker", 99, 99, 99, BiologicalSex.Unspecified, UnitSystem.Imperial);
    }

    function test_profile_emitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit IDiveLog.ProfileUpdated();
        diveLog.updateProfile("Updated", 31, 73, 190, BiologicalSex.Male, UnitSystem.Metric);
    }

    // ===== supportsInterface =====

    function test_supportsInterface() public {
        assertTrue(diveLog.supportsInterface(type(IERC165).interfaceId));
        assertTrue(diveLog.supportsInterface(type(IDiveLog).interfaceId));
        assertFalse(diveLog.supportsInterface(0xffffffff));
    }

    // ===== fuzz tests =====

    function testFuzz_logDive_depth(int32 depth) public {
        vm.assume(depth > 0);
        DiveData memory data = _makeDiveData();
        data.maxDepth = depth;
        vm.prank(owner);
        uint256 id = diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "");
        assertEq(diveLog.getDive(id).data.maxDepth, depth);
    }

    function testFuzz_logDive_bottomTime(uint32 bt) public {
        vm.assume(bt > 0);
        DiveData memory data = _makeDiveData();
        data.bottomTimeMinutes = bt;
        vm.prank(owner);
        uint256 id = diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "");
        assertEq(diveLog.getDive(id).data.bottomTimeMinutes, bt);
    }

    function testFuzz_logDive_revert_zeroOrNegativeDepth(int32 depth) public {
        vm.assume(depth <= 0);
        DiveData memory data = _makeDiveData();
        data.maxDepth = depth;
        vm.prank(owner);
        vm.expectRevert(IDiveLog.InvalidDepth.selector);
        diveLog.logDive(DIVE_DATE, UnitSystem.Imperial, data, _makeEnvironment(), _makeDecompression(), _makeGasData(), "");
    }

    // ===== sovereign deployment =====

    function test_sovereignDeployment() public {
        address diver = makeAddr("diver");
        vm.prank(diver);
        SovereignDiveLog sovereign = new SovereignDiveLog(
            diver,
            "Jane Doe",
            28,
            165,
            60,
            BiologicalSex.Female,
            UnitSystem.Metric
        );

        assertEq(sovereign.owner(), diver);

        DiverProfile memory p = sovereign.profile();
        assertEq(p.name, "Jane Doe");
        assertEq(uint256(p.units), uint256(UnitSystem.Metric));

        assertTrue(sovereign.supportsInterface(type(IDiveLog).interfaceId));
    }
}
