// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {EffectStep, MonStateIndexName} from "../../Enums.sol";
import {IEngine} from "../../IEngine.sol";
import {IEffect} from "../IEffect.sol";

import {StatusEffect} from "./StatusEffect.sol";

contract BurnStatus is StatusEffect {
    uint256 constant DURATION = 5;

    constructor(IEngine engine) StatusEffect(engine) {}

    function name() public pure override returns (string memory) {
        return "Burn";
    }

    function shouldRunAtStep(EffectStep r) external pure override returns (bool) {
        return r == EffectStep.RoundEnd || r == EffectStep.OnApply;
    }

    // On apply, reduce attack by 50% and set duration
    function onApply(uint256, bytes memory, uint256 targetIndex, uint256 monIndex)
        external
        override
        returns (bytes memory updatedExtraData)
    {
        bytes32 battleKey = ENGINE.battleKeyForWrite();
        
        // Get max attack to calculate 50% reduction
        uint32 maxAttack = ENGINE.getMonValueForBattle(battleKey, targetIndex, monIndex, MonStateIndexName.Attack);
        ENGINE.updateMonState(targetIndex, monIndex, MonStateIndexName.Attack, -int32(maxAttack / 2));
        
        return abi.encode(DURATION);
    }

    // At the end of each round, apply burn damage (1/16 of max HP) and check duration
    function onRoundEnd(uint256, bytes memory extraData, uint256 targetIndex, uint256 monIndex)
        external
        override
        returns (bytes memory, bool removeAfterRun)
    {
        bytes32 battleKey = ENGINE.battleKeyForWrite();
        
        // Get current HP delta and max HP
        int32 hpDelta = ENGINE.getMonStateForBattle(battleKey, targetIndex, monIndex, MonStateIndexName.Hp);
        uint32 maxHp = ENGINE.getMonValueForBattle(battleKey, targetIndex, monIndex, MonStateIndexName.Hp);
        
        // Calculate burn damage (1/16 of max HP)
        uint32 burnDamage = maxHp / 16;
        
        // Only apply damage if it won't reduce HP below 1
        if (hpDelta + int32(maxHp) > int32(burnDamage)) {
            ENGINE.updateMonState(targetIndex, monIndex, MonStateIndexName.Hp, -int32(burnDamage));
        }

        // Check duration
        uint256 turnsLeft = abi.decode(extraData, (uint256));
        if (turnsLeft == 1) {
            // When effect ends, restore attack
            uint32 maxAttack = ENGINE.getMonValueForBattle(battleKey, targetIndex, monIndex, MonStateIndexName.Attack);
            ENGINE.updateMonState(targetIndex, monIndex, MonStateIndexName.Attack, int32(maxAttack / 2));
            return (extraData, true);
        } else {
            return (abi.encode(turnsLeft - 1), false);
        }
    }
}
