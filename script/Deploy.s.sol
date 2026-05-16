// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {SovereignDiveLog} from "../src/SovereignDiveLog.sol";


contract DeploySovereignDiveLog is Script {
    function run() external {
        address diver = vm.envAddress("DIVER_ADDRESS");

        vm.startBroadcast();
        new SovereignDiveLog(diver);
        vm.stopBroadcast();
    }
}
