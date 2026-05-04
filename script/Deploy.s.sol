// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DiveLogRegistry} from "../src/DiveLogRegistry.sol";

contract DeployDiveLogRegistry is Script {
    function run() external {
        vm.startBroadcast();
        new DiveLogRegistry();
        vm.stopBroadcast();
    }
}
