// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IDiveLogTypes.sol";
import "./interfaces/IDiveLogBook.sol";

contract DiveLogBook is IDiveLogBook {
    address public immutable owner;
    address public immutable registry;

    DiverProfile internal _profile;
    uint256 public diveCount;

    mapping(uint256 => DiveLog) private _dives;
    mapping(uint64 => uint256[]) private _divesByDate;

    constructor(
        address _owner,
        string memory _name,
        uint8 _age,
        uint16 _height,
        uint16 _weight,
        BiologicalSex _sex,
        UnitSystem _units
    ) {
        owner = _owner;
        registry = msg.sender;
        _profile = DiverProfile({
            name: _name,
            age: _age,
            height: _height,
            weight: _weight,
            sex: _sex,
            units: _units
        });
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IDiveLogBook).interfaceId;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
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
        if (units.length != len || dataArr.length != len || envArr.length != len
            || decompArr.length != len || gasArr.length != len || remarksArr.length != len) {
            revert ArrayLengthMismatch();
        }

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
            if (diveIds[i] == 0 || diveIds[i] > diveCount) revert DiveNotFound(diveIds[i]);
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

    function profile() external view override returns (DiverProfile memory) {
        return _profile;
    }

    function updateProfile(
        string calldata _name,
        uint8 _age,
        uint16 _height,
        uint16 _weight,
        BiologicalSex _sex,
        UnitSystem _units
    ) external onlyOwner {
        _profile = DiverProfile({
            name: _name,
            age: _age,
            height: _height,
            weight: _weight,
            sex: _sex,
            units: _units
        });
        emit ProfileUpdated();
    }

    function getDiveCount() external view returns (uint256) {
        return diveCount;
    }
}
