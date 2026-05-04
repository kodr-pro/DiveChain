// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IDiveLogTypes.sol";
import "./interfaces/IDiveLogRegistry.sol";
import "./DiveLogBook.sol";

contract DiveLogRegistry is IDiveLogRegistry {
    address public immutable deployer;

    uint256 public totalDivers;

    mapping(address => address) public diverToLogBook;
    mapping(address => bool) public isRegistered;
    mapping(uint256 => address) public diverAtIndex;

    address[] private _allLogBooks;

    constructor() {
        deployer = msg.sender;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC165).interfaceId
            || interfaceId == type(IDiveLogRegistry).interfaceId;
    }

    function registerDiver(
        string calldata _name,
        uint8 _age,
        uint16 _height,
        uint16 _weight,
        BiologicalSex _sex,
        UnitSystem _units
    ) external returns (address) {
        if (isRegistered[msg.sender]) revert AlreadyRegistered();
        if (bytes(_name).length == 0) revert EmptyName();

        DiveLogBook logBook = new DiveLogBook(
            msg.sender,
            _name,
            _age,
            _height,
            _weight,
            _sex,
            _units
        );

        address logBookAddr = address(logBook);

        isRegistered[msg.sender] = true;
        diverToLogBook[msg.sender] = logBookAddr;
        diverAtIndex[totalDivers] = msg.sender;
        _allLogBooks.push(logBookAddr);

        emit DiverRegistered(msg.sender, logBookAddr, totalDivers);

        unchecked { ++totalDivers; }

        return logBookAddr;
    }

    function getLogBook(address diver) external view returns (address) {
        if (!isRegistered[diver]) revert NotRegistered();
        return diverToLogBook[diver];
    }

    function getMyLogBook() external view returns (address) {
        if (!isRegistered[msg.sender]) revert NotRegistered();
        return diverToLogBook[msg.sender];
    }

    function getAllLogBooks() external view returns (address[] memory) {
        return _allLogBooks;
    }

    function getLogBookPage(uint256 offset, uint256 limit) external view returns (address[] memory) {
        uint256 total = _allLogBooks.length;
        if (offset >= total) return new address[](0);

        uint256 end = offset + limit;
        if (end > total) end = total;

        address[] memory page = new address[](end - offset);
        for (uint256 i = offset; i < end; ) {
            page[i - offset] = _allLogBooks[i];
            unchecked { ++i; }
        }
        return page;
    }
}
