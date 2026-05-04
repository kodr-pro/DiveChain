// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum UnitSystem { Imperial, Metric }
enum DiveMode { SSA, SCUBA }
enum BreathingGas { Air, Nitrox, Heliox, Trimix, Oxygen, Mixed }
enum DivePurpose {
    Training, Inspection, Repair, Search, Salvage,
    Recovery, Construction, Research, EOD, Security,
    Photographic, Recreational, Other
}
enum SuitType { Wet, Dry, HotWater, Swim }
enum DecompressionType { NoneDecomp, Standard, SurfaceDecompO2, SurfaceDecompAir, Saturation, Repetitive, ExceptionalExposure }

struct DiveLog {
    uint256 id;
    uint64 diveDate;
    UnitSystem units;
    DiveData data;
    Environment env;
    Decompression decomp;
    GasData gas;
    string remarks;
}

struct DiveData {
    uint32 leaveSurfaceTime;
    uint32 leaveBottomTime;
    uint32 reachSurfaceTime;
    uint32 bottomTimeMinutes;
    int32 maxDepth;
    int32 averageDepth;
    DiveMode mode;
    DivePurpose purpose;
    SuitType suit;
}

struct Environment {
    int32 airTemp;
    int32 waterTemp;
    int16 currentKnots;
    string location;
    string bottomType;
    string weatherConditions;
}

struct Decompression {
    DecompressionType decompType;
    uint32 totalDecompTimeMinutes;
    int32 maxDepthAttained;
    bytes32 tableSchedule;
    bytes1 repetitiveGroup;
    uint32 surfaceIntervalMinutes;
    bytes1 newRepetitiveGroup;
}

struct GasData {
    BreathingGas gasType;
    uint16 o2Percent;
    uint16 hePercent;
    uint16 n2Percent;
    uint32 airInPsi;
    uint32 airOutPsi;
    uint32 airUsedPsi;
    uint32 bailoutPressure;
}

struct DiverProfile {
    string name;
    uint8 age;
    uint16 height;
    uint16 weight;
    bool isMale;
    UnitSystem units;
}

contract DiveLogBook {
    address public immutable owner;
    address public immutable registry;

    DiverProfile public profile;
    uint256 public diveCount;

    mapping(uint256 => DiveLog) private _dives;
    mapping(uint64 => uint256[]) private _divesByDate;

    event DiveLogged(uint256 indexed diveId, uint64 indexed diveDate);
    event ProfileUpdated();

    error NotOwner();
    error NotRegistry();
    error InvalidDepth();
    error InvalidTimes();
    error DiveNotFound(uint256 diveId);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyRegistry() {
        if (msg.sender != registry) revert NotRegistry();
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        uint8 _age,
        uint16 _height,
        uint16 _weight,
        bool _isMale,
        UnitSystem _units
    ) {
        owner = _owner;
        registry = msg.sender;
        profile = DiverProfile({
            name: _name,
            age: _age,
            height: _height,
            weight: _weight,
            isMale: _isMale,
            units: _units
        });
    }

    function logDive(
        uint64 diveDate,
        UnitSystem units,
        DiveData calldata data,
        Environment calldata env,
        Decompression calldata decomp,
        GasData calldata gas,
        string calldata remarks
    ) external onlyOwner returns (uint256) {
        if (data.maxDepth <= 0) revert InvalidDepth();
        if (data.bottomTimeMinutes == 0) revert InvalidTimes();

        uint256 diveId = ++diveCount;

        _dives[diveId] = DiveLog({
            id: diveId,
            diveDate: diveDate,
            units: units,
            data: data,
            env: env,
            decomp: decomp,
            gas: gas,
            remarks: remarks
        });

        _divesByDate[diveDate].push(diveId);

        emit DiveLogged(diveId, diveDate);
        return diveId;
    }

    function batchLogDives(
        uint64[] calldata diveDates,
        UnitSystem[] calldata units,
        DiveData[] calldata dataArr,
        Environment[] calldata envArr,
        Decompression[] calldata decompArr,
        GasData[] calldata gasArr,
        string[] calldata remarksArr
    ) external onlyOwner returns (uint256[] memory) {
        uint256 len = diveDates.length;
        uint256[] memory ids = new uint256[](len);

        for (uint256 i; i < len; ) {
            if (dataArr[i].maxDepth <= 0) revert InvalidDepth();
            if (dataArr[i].bottomTimeMinutes == 0) revert InvalidTimes();

            uint256 diveId = ++diveCount;

            _dives[diveId] = DiveLog({
                id: diveId,
                diveDate: diveDates[i],
                units: units[i],
                data: dataArr[i],
                env: envArr[i],
                decomp: decompArr[i],
                gas: gasArr[i],
                remarks: remarksArr[i]
            });

            _divesByDate[diveDates[i]].push(diveId);
            ids[i] = diveId;

            emit DiveLogged(diveId, diveDates[i]);

            unchecked { ++i; }
        }

        return ids;
    }

    function getDive(uint256 diveId) external view returns (DiveLog memory) {
        if (diveId == 0 || diveId > diveCount) revert DiveNotFound(diveId);
        return _dives[diveId];
    }

    function getDivesByDate(uint64 date) external view returns (uint256[] memory) {
        return _divesByDate[date];
    }

    function getMultipleDives(uint256[] calldata diveIds) external view returns (DiveLog[] memory) {
        uint256 len = diveIds.length;
        DiveLog[] memory dives = new DiveLog[](len);
        for (uint256 i; i < len; ) {
            dives[i] = _dives[diveIds[i]];
            unchecked { ++i; }
        }
        return dives;
    }

    function getAllDiveIds() external view returns (uint256[] memory) {
        uint256 total = diveCount;
        uint256[] memory ids = new uint256[](total);
        for (uint256 i; i < total; ) {
            ids[i] = i + 1;
            unchecked { ++i; }
        }
        return ids;
    }

    function updateProfile(
        string calldata _name,
        uint8 _age,
        uint16 _height,
        uint16 _weight,
        bool _isMale,
        UnitSystem _units
    ) external onlyOwner {
        profile = DiverProfile({
            name: _name,
            age: _age,
            height: _height,
            weight: _weight,
            isMale: _isMale,
            units: _units
        });
        emit ProfileUpdated();
    }

    function getDiveCount() external view returns (uint256) {
        return diveCount;
    }
}
