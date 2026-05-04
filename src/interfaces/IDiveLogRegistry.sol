// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import "./IDiveLogTypes.sol";
import "./IERC165.sol";

interface IDiveLogRegistry is IERC165 {
    event DiverRegistered(address indexed diver, address indexed logBook, uint256 diverId);

    error AlreadyRegistered();
    error NotRegistered();
    error EmptyName();

    function registerDiver(
        string calldata name,
        uint8 age,
        uint16 height,
        uint16 weight,
        BiologicalSex sex,
        UnitSystem units
    ) external returns (address logBook);

    function getLogBook(address diver) external view returns (address);
    function getMyLogBook() external view returns (address);
    function isRegistered(address diver) external view returns (bool);
    function totalDivers() external view returns (uint256);
}
