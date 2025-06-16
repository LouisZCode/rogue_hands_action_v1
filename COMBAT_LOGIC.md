# Combat Logic System

## Core Combat Mechanics

This document defines the complete combat system for Rogue Hands, including damage calculation, defense points, and stun mechanics.

## Health & Defense Systems

### Health Points
- **Player**: 100 HP
- **Enemy**: 60 HP

### Defense Points
- **Player**: 3 Defense Points
- **Enemy**: 1 Defense Point
- **Usage**: Consumed when defending with same stance as incoming attack
- **Effect**: Blocks damage but reduces defense points by 1

## Combat Scenarios

The combat system recognizes two distinct scenarios:

### Scenario 1: Attack vs Defense
**Situation**: One character attacks (dashing), other is in stance but not dashing

**Damage Rules**:
1. **vs Neutral Stance**: 1 damage
2. **Parry (attacker loses stance matchup)**: 0 damage, attacker becomes stunned
3. **Same Stance Defense**: 0 damage, defender loses 1 defense point
4. **Win (attacker stronger stance)**: 2 damage

### Scenario 2: Mutual Attacks
**Situation**: Both characters dashing/attacking simultaneously

**Damage Rules**:
1. **Different winning stances**: Winner deals 2 damage, loser becomes stunned
2. **Same stances (tie)**: 0 damage to both, no stun
3. **Note**: vs Neutral not applicable (both must be attacking)

## Rock-Paper-Scissors Rules

**Winning Matchups**:
- Rock beats Scissors
- Paper beats Rock
- Scissors beats Paper

## Stun System

### Stun Triggers
- Attacking with losing stance in any scenario
- Duration: TBD (to be balanced during testing)

### Stun Effects
- Character cannot move or change stances
- Visual indicator shows stunned state
- Auto-recovery after timer expires

## Defense Point System

### Consumption
- Used only when defending with same stance as incoming attack
- Prevents damage but costs 1 defense point
- When depleted: same-stance defense fails (takes damage instead)

### Regeneration
- **TBD**: Regeneration timing and conditions to be determined during balancing

## Tactical Implications

### Resource Management
- Defense points create strategic resource to manage
- Players must decide when to use defense vs dodge/reposition

### Timing Strategy
- Mutual attacks create high-risk, high-reward scenarios
- Stun punishment encourages careful stance selection

### Positioning
- Neutral stance remains safe but limits offensive options
- Combat stances enable attacks but create vulnerability windows

## Implementation Status

**Phase 1: Documentation** ✅ Complete
**Phase 2: Defense Points** - In Progress
**Phase 3: Scenario Detection** - Pending
**Phase 4: Damage Calculation** - Pending
**Phase 5: Stun System** - Pending
**Phase 6: Integration Testing** - Pending

## Testing Requirements

Each phase requires testing to verify:
1. UI elements display correctly
2. Logic calculations work as expected
3. Edge cases are handled properly
4. Visual feedback is clear and responsive
5. Game balance feels fair and strategic

## Files Modified

1. `/Scripts/Player.gd` - Defense points, stun state, damage logic
2. `/Scripts/Enemy.gd` - Defense points, stun enhancement, damage logic
3. `/Scripts/GameManager.gd` - UI management for defense points
4. `/scenes/main.tscn` - UI elements for defense point display
5. Combat damage calculation functions (shared logic)

## Legacy Combat System

Previous implementation focused on:
- Basic Rock-Paper-Scissors damage (5/10/30)
- Attack cooldowns and auto-return mechanics
- Visual feedback systems

New system builds upon this foundation while adding tactical depth through defense points and stun mechanics.