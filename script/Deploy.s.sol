// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {SovereignDiveLog} from "../src/SovereignDiveLog.sol";
import {BiologicalSex, UnitSystem} from "../src/interfaces/IDiveLogTypes.sol";

contract DeploySovereignDiveLog is Script {
    function run() external {
        address diver = vm.envAddress("DIVER_ADDRESS");
        string memory name = vm.envString("DIVER_NAME");
        uint8 age = uint8(vm.envUint("DIVER_AGE"));
        uint16 height = uint16(vm.envUint("DIVER_HEIGHT"));
        uint16 weight = uint16(vm.envUint("DIVER_WEIGHT"));
        BiologicalSex sex = BiologicalSex(vm.envUint("DIVER_SEX"));
        UnitSystem units = UnitSystem(vm.envUint("DIVER_UNITS"));

        vm.startBroadcast();
        new SovereignDiveLog(diver, name, age, height, weight, sex, units);
        vm.stopBroadcast();
    }
}
