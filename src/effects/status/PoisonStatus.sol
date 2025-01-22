// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {EffectStep, MonStateIndexName} from "../../Enums.sol";
import {IEngine} from "../../IEngine.sol";
import {IEffect} from "../IEffect.sol";

import {StatusEffect} from "./StatusEffect.sol";

contract PoisonStatus is StatusEffect {
    uint256 constant DURATION = 5; // Default duration for poison

    constructor(IEngine engine) StatusEffect(engine) {}

    function name() public pure override returns (string memory) {
        return "Poison";
    }

    function shouldRunAtStep(EffectStep r) external pure override returns (bool) {
        return r == EffectStep.RoundEnd || r == EffectStep.OnApply;
    }

    // On apply, set the initial duration
    function onApply(uint256, bytes memory, uint256, uint256)
        external
        pure
        override
        returns (bytes memory updatedExtraData)
    {
        return abi.encode(DURATION);
    }

    // At the end of each round, apply poison damage (1/8 of max HP) and check duration
    function onRoundEnd(uint256, bytes memory extraData, uint256 targetIndex, uint256 monIndex)
        external
        override
        returns (bytes memory, bool removeAfterRun)
    {
        bytes32 battleKey = ENGINE.battleKeyForWrite();
        
        // Get current HP delta and max HP
        int32 hpDelta = ENGINE.getMonStateForBattle(battleKey, targetIndex, monIndex, MonStateIndexName.Hp);
        uint32 maxHp = ENGINE.getMonValueForBattle(battleKey, targetIndex, monIndex, MonStateIndexName.Hp);
        
        // Calculate poison damage (1/8 of max HP)
        uint32 poisonDamage = maxHp / 8;
        
        // Only apply damage if it won't reduce HP below 1
        if (hpDelta + int32(maxHp) > int32(poisonDamage)) {
            ENGINE.updateMonState(targetIndex, monIndex, MonStateIndexName.Hp, -int32(poisonDamage));
        }

        // Check duration
        uint256 turnsLeft = abi.decode(extraData, (uint256));
        if (turnsLeft == 1) {
            return (extraData, true);
        } else {
            return (abi.encode(turnsLeft - 1), false);
        }
    }
}
