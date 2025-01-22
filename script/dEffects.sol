// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import "../src/Enums.sol";

import {Engine} from "../src/Engine.sol";
import {FrightStatus} from "../src/effects/status/FrightStatus.sol";

import {FrostbiteStatus} from "../src/effects/status/FrostbiteStatus.sol";
import {SleepStatus} from "../src/effects/status/SleepStatus.sol";
import {PoisonStatus} from "../src/effects/status/PoisonStatus.sol";
import {BurnStatus} from "../src/effects/status/BurnStatus.sol";

contract dEffects is Script {
    function run()
        external
        returns (
            FrightStatus frightStatus,
            SleepStatus sleepStatus,
            FrostbiteStatus frostbiteStatus,
            PoisonStatus poisonStatus,
            BurnStatus burnStatus
        )
    {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));
        vm.startBroadcast(deployerPrivateKey);
        Engine engine = Engine(vm.envAddress("ENGINE"));
        frightStatus = new FrightStatus(engine);
        sleepStatus = new SleepStatus(engine);
        frostbiteStatus = new FrostbiteStatus(engine);
        poisonStatus = new PoisonStatus(engine);
        burnStatus = new BurnStatus(engine);
    }
}