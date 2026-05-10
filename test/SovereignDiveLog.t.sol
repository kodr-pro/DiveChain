// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {SovereignDiveLog} from "../src/SovereignDiveLog.sol";
import {UnitSystem, DiveMode, BreathingGas, DivePurpose, SuitType, DecompressionType, BiologicalSex, DiveData, Environment, Decompression, GasData, DiverProfile, DiveLog, DiveInput, VoidInfo, Attestation} from "../src/interfaces/IDiveLogTypes.sol";
import {IDiveLog} from "../src/interfaces/IDiveLog.sol";
import {IERC165} from "../src/interfaces/IERC165.sol";
import {DiveLogTypedData} from "../src/interfaces/IDiveLogTypedData.sol";

contract SovereignDiveLogTest is Test {
    SovereignDiveLog public diveLog;
    address public owner = makeAddr("owner");
    address public stranger = makeAddr("stranger");
    address public buddy;
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

    function _makeDiveInput() internal pure returns (DiveInput memory) {
        return DiveInput({
            diveDate: DIVE_DATE,
            units: UnitSystem.Imperial,
            data: _makeDiveData(),
            env: _makeEnvironment(),
            decomp: _makeDecompression(),
            gas: _makeGasData(),
            remarks: "Hull inspection, starboard side."
        });
    }

    function _logDive() internal returns (uint256) {
        vm.prank(owner);
        return diveLog.logDive(_makeDiveInput());
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
        diveLog.logDive(_makeDiveInput());
    }

    function test_logDive_sequentialIds() public {
        vm.startPrank(owner);
        for (uint256 i; i < 5; i++) {
            DiveInput memory input = _makeDiveInput();
            input.diveDate = DIVE_DATE + uint64(i * 86400);
            uint256 id = diveLog.logDive(input);
            assertEq(id, i + 1);
        }
        vm.stopPrank();
        assertEq(diveLog.diveCount(), 5);
    }

    function test_revert_logDive_notOwner() public {
        vm.prank(stranger);
        vm.expectRevert(IDiveLog.NotOwner.selector);
        diveLog.logDive(_makeDiveInput());
    }

    function test_revert_zeroDepth() public {
        DiveInput memory input = _makeDiveInput();
        input.data.maxDepth = 0;
        vm.prank(owner);
        vm.expectRevert(IDiveLog.InvalidDepth.selector);
        diveLog.logDive(input);
    }

    function test_revert_negativeDepth() public {
        DiveInput memory input = _makeDiveInput();
        input.data.maxDepth = -10;
        vm.prank(owner);
        vm.expectRevert(IDiveLog.InvalidDepth.selector);
        diveLog.logDive(input);
    }

    function test_revert_zeroBottomTime() public {
        DiveInput memory input = _makeDiveInput();
        input.data.bottomTimeMinutes = 0;
        vm.prank(owner);
        vm.expectRevert(IDiveLog.InvalidTimes.selector);
        diveLog.logDive(input);
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
        DiveInput memory input1 = _makeDiveInput();
        input1.remarks = "Dive 1";
        diveLog.logDive(input1);

        DiveInput memory input2 = _makeDiveInput();
        input2.remarks = "Dive 2";
        diveLog.logDive(input2);

        DiveInput memory input3 = _makeDiveInput();
        input3.diveDate = DIVE_DATE + 86400;
        input3.remarks = "Dive 3";
        diveLog.logDive(input3);
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
        DiveInput memory input1 = _makeDiveInput();
        input1.remarks = "Dive 1";
        diveLog.logDive(input1);

        DiveInput memory input2 = _makeDiveInput();
        input2.diveDate = DIVE_DATE + 86400;
        input2.remarks = "Dive 2";
        diveLog.logDive(input2);
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
            DiveInput memory input = _makeDiveInput();
            input.diveDate = DIVE_DATE + uint64(i * 86400);
            diveLog.logDive(input);
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
        DiveInput[] memory inputs = new DiveInput[](3);

        for (uint256 i; i < 3; i++) {
            inputs[i] = _makeDiveInput();
            inputs[i].diveDate = DIVE_DATE + uint64(i * 86400);
            inputs[i].remarks = "Batch dive";
        }

        vm.prank(owner);
        uint256[] memory ids = diveLog.batchLogDives(inputs);

        assertEq(ids.length, 3);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);
        assertEq(ids[2], 3);
        assertEq(diveLog.diveCount(), 3);
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
        diveLog.logDive(_makeDiveInput());

        DiveInput memory corrected = _makeDiveInput();
        corrected.data.maxDepth = 100;
        corrected.remarks = "Corrected dive";
        diveLog.logDive(corrected);

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

    // ===== attestDive =====

    function test_attestDive() public {
        _logDive();

        uint256 nonce = diveLog.attesterNonce(buddy);
        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid, nonce);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectEmit(true, true, false, true);
        emit IDiveLog.DiveAttested(1, buddy);
        diveLog.attestDive(1, nonce, signature);

        Attestation[] memory attestations = diveLog.getAttestations(1);
        assertEq(attestations.length, 1);
        assertEq(attestations[0].attester, buddy);
        assertGt(attestations[0].attestedAt, 0);
    }

    function test_attestDive_incrementsNonce() public {
        _logDive();

        uint256 nonce0 = diveLog.attesterNonce(buddy);
        assertEq(nonce0, 0);

        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid, nonce0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        diveLog.attestDive(1, nonce0, signature);

        uint256 nonce1 = diveLog.attesterNonce(buddy);
        assertEq(nonce1, 1);
    }

    function test_attestDive_multipleAttestations() public {
        _logDive();

        (address buddy2, uint256 buddy2Pk) = makeAddrAndKey("buddy2");

        uint256 nonce1 = diveLog.attesterNonce(buddy);
        bytes32 digest1 = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid, nonce1);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(buddyPk, digest1);
        bytes memory sig1 = abi.encodePacked(r1, s1, v1);

        uint256 nonce2 = diveLog.attesterNonce(buddy2);
        bytes32 digest2 = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid, nonce2);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(buddy2Pk, digest2);
        bytes memory sig2 = abi.encodePacked(r2, s2, v2);

        diveLog.attestDive(1, nonce1, sig1);
        diveLog.attestDive(1, nonce2, sig2);

        Attestation[] memory attestations = diveLog.getAttestations(1);
        assertEq(attestations.length, 2);
        assertEq(attestations[0].attester, buddy);
        assertEq(attestations[1].attester, buddy2);
    }

    function test_revert_attestDive_nonceMismatch() public {
        _logDive();

        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid, 5);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(IDiveLog.NonceMismatch.selector, uint256(0), uint256(5)));
        diveLog.attestDive(1, 5, signature);
    }

    function test_revert_attestDive_alreadyAttested() public {
        _logDive();

        uint256 nonce = diveLog.attesterNonce(buddy);
        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid, nonce);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        diveLog.attestDive(1, nonce, signature);

        uint256 nextNonce = nonce + 1;
        bytes32 digest2 = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid, nextNonce);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(buddyPk, digest2);
        bytes memory signature2 = abi.encodePacked(r2, s2, v2);

        vm.expectRevert(abi.encodeWithSelector(IDiveLog.AlreadyAttested.selector, uint256(1), buddy));
        diveLog.attestDive(1, nextNonce, signature2);
    }

    function test_revert_attestDive_invalidSignature() public {
        _logDive();

        bytes memory badSignature = new bytes(65);
        vm.expectRevert(IDiveLog.InvalidSignature.selector);
        diveLog.attestDive(1, 0, badSignature);
    }

    function test_revert_attestDive_notFound() public {
        bytes memory signature = new bytes(65);
        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveNotFound.selector, uint256(99)));
        diveLog.attestDive(99, 0, signature);
    }

    function test_revert_attestDive_voidedDive() public {
        _logDive();

        vm.prank(owner);
        diveLog.voidDive(1, 0, "Voided");

        uint256 nonce = diveLog.attesterNonce(buddy);
        bytes32 digest = DiveLogTypedData.attestationDigest(1, address(diveLog), block.chainid, nonce);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buddyPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(abi.encodeWithSelector(IDiveLog.DiveAlreadyVoided.selector, uint256(1)));
        diveLog.attestDive(1, nonce, signature);
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
        DiveInput memory input = _makeDiveInput();
        input.data.maxDepth = depth;
        vm.prank(owner);
        uint256 id = diveLog.logDive(input);
        assertEq(diveLog.getDive(id).data.maxDepth, depth);
    }

    function testFuzz_logDive_bottomTime(uint32 bt) public {
        vm.assume(bt > 0);
        DiveInput memory input = _makeDiveInput();
        input.data.bottomTimeMinutes = bt;
        vm.prank(owner);
        uint256 id = diveLog.logDive(input);
        assertEq(diveLog.getDive(id).data.bottomTimeMinutes, bt);
    }

    function testFuzz_logDive_revert_zeroOrNegativeDepth(int32 depth) public {
        vm.assume(depth <= 0);
        DiveInput memory input = _makeDiveInput();
        input.data.maxDepth = depth;
        vm.prank(owner);
        vm.expectRevert(IDiveLog.InvalidDepth.selector);
        diveLog.logDive(input);
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
