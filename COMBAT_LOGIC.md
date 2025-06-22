# Combat Logic System

## Core Combat Mechanics

This document defines the complete combat system for Rogue Hands, including damage calculation, defense points, parry system, and stun mechanics.

## Health & Defense Systems

### Health Points
- **Player**: 5 HP (displayed as hearts ❤️💔)
- **Enemy**: 5 HP (health bar display)

### Defense Points
- **Player**: 3 Defense Points (displayed as shields 🛡️💔)
- **Enemy**: 1 Defense Point (displayed as shield emoji)
- **Usage**: Consumed when defending with same stance as incoming attack
- **Effect**: Blocks damage but reduces defense points by 1
- **Visual Feedback**: Blue circles around player that expand and fade when consumed

## Parry System

### Perfect Parry Window
- **Duration**: 0.5 seconds after entering a combat stance
- **Visual Indicator**: Green circle that fades over the parry window duration
- **Trigger**: Entering Rock, Paper, or Scissors stance
- **Effect**: If attacked during this window with a losing attack, executes perfect parry

### Perfect Parry Benefits
- **Damage**: 0 damage to defender
- **Stun**: Attacker becomes stunned for 3 seconds
- **Visual Feedback**: Gold flash on parry circle, screen shake, perfect parry sound
- **Tactical**: Rewards precise timing and stance prediction

## Combat Scenarios

The combat system recognizes two distinct scenarios:

### Scenario 1: Attack vs Defense
**Situation**: One character attacks (dashing), other is in stance but not dashing

**Damage Rules**:
1. **vs Neutral Stance**: 1 damage (reduced by neutral stance defense)
2. **Perfect Parry**: 0 damage, attacker stunned (within 0.5s parry window)
3. **Regular Block**: 0 damage, defender loses 1 defense point (outside parry window)
4. **Same Stance Defense**: 
   - With defense points: 0 damage, defender loses 1 defense point
   - Without defense points: 1 damage (balanced tie damage)
5. **Win (attacker stronger stance)**: 2 damage

### Scenario 2: Mutual Attacks
**Situation**: Both characters dashing/attacking simultaneously

**Damage Rules**:
1. **Different winning stances**: Winner deals 2 damage, loser becomes stunned
2. **Same stances (tie)**: 0 damage to both, no stun
3. **Note**: Parry window not applicable (both are attacking)

## Rock-Paper-Scissors Rules

**Winning Matchups**:
- Rock beats Scissors
- Paper beats Rock
- Scissors beats Paper

## Stun System

### Stun Triggers
- **Perfect Parry**: Attacking into a perfect parry window
- **Mutual Attack Loss**: Losing stance matchup in mutual attacks
- **Duration**: 3 seconds for both player and enemy

### Stun Effects
- Character cannot move or change stances
- Auto-return to neutral stance
- Visual indicator (💫) shows stunned state
- Purple color tint during stun
- Auto-recovery after timer expires
- Cancels any ongoing dashes

## Defense Point System

### Consumption
- Used only when defending with same stance as incoming attack
- Prevents damage but costs 1 defense point
- When depleted: same-stance defense fails (takes damage instead)

### Regeneration
- **Current**: No regeneration (fixed resource per battle)
- **Future**: Regeneration mechanics to be considered during balancing

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

### Parry Timing
- Perfect parry window rewards precise stance prediction
- Risk vs reward: enter stance early for parry opportunity
- Defensive circles show current defense resources

## User Interface

### Health Display
- **Hearts**: ❤️ for current health, 💔 for missing health
- **Location**: Top-left corner
- **Dynamic**: Scales based on max health

### Defense Points Display  
- **Shields**: 🛡️ for active defense, 💔 for consumed defense
- **Location**: Below hearts (top-left)
- **Visual Circles**: Blue concentric circles around player during combat stances

### Attack Cooldown
- **Progress Bar**: Below player character
- **Visibility**: Only shown while charging (1 second cooldown)
- **Color**: Red while charging, green when ready

### Stance Indicator
- **Location**: Bottom-right corner
- **Display**: Current stance with emoji and color coding
- **Colors**: Blue (Neutral), Gray (Rock), White (Paper), Yellow (Scissors)

### Parry Visual
- **Green Circle**: Appears during 0.5s parry window
- **Gold Flash**: Perfect parry success feedback
- **Fade Animation**: Shows remaining parry window time

## Controls

### Movement
- **Arrow Keys**: 8-directional movement (only in neutral stance)
- **Smooth Movement**: Acceleration/deceleration system for responsive feel

### Combat Stances
- **A Key**: Rock stance ✊
- **S Key**: Paper stance ✋  
- **D Key**: Scissors stance ✌️
- **Release**: Auto-return to neutral 👤

### Attacks
- **Space + Direction**: Dash attack in held direction
- **Requirements**: Must be in combat stance + hold direction + space
- **Cooldown**: 1 second (only recovers in neutral stance)

## Implementation Status

**Phase 1: Core Combat System** ✅ Complete
- Rock-Paper-Scissors damage calculation
- Mutual vs single attack detection
- Attack cooldowns and stance management

**Phase 2: Defense Points** ✅ Complete
- Player 3-point, Enemy 1-point system
- UI display with shield emojis
- Visual circles during combat stances

**Phase 3: Parry System** ✅ Complete
- 0.5 second perfect parry windows
- Visual feedback with green circles
- Perfect parry rewards and stun punishment

**Phase 4: Stun System** ✅ Complete
- 3-second stun duration
- Visual indicators and sound effects
- Movement and stance restrictions

**Phase 5: UI Enhancement** ✅ Complete
- Heart health display system
- Attack cooldown bar repositioning
- Clean UI layout with grouped elements

**Phase 6: Audio Integration** ✅ Complete
- Comprehensive SFX for all combat actions
- Perfect parry, stun, and stance change sounds
- Walking and environmental audio

## Audio System

### Combat Sounds
- **Perfect Parry**: Distinctive success sound
- **Player Hit**: Light and heavy variants
- **Enemy Hit/Death**: Impact and defeat sounds
- **Stance Changes**: UI feedback sounds
- **Defense Consumption**: Shield break audio

### Environmental Audio
- **Walking**: Footstep sounds with start/stop logic
- **Player Stun**: Disorientation audio effect

## Files Modified

### Core Scripts
1. `/Scripts/Player.gd` - Complete combat, parry, and movement system
2. `/Scripts/Enemy.gd` - AI combat system with tactical decision making
3. `/Scripts/GameManager.gd` - UI management and game state coordination
4. `/Scripts/AudioManager.gd` - Comprehensive audio system
5. `/Scripts/ParryCircle.gd` - Parry window visual feedback
6. `/Scripts/DefenseCircles.gd` - Defense point visual system

### Scene Files
7. `/scenes/Player.tscn` - Player with all UI and audio components
8. `/scenes/Enemy.tscn` - Enemy with combat areas and audio
9. `/scenes/main.tscn` - Clean UI layout with heart and defense displays

### Assets
10. Multiple SFX files for complete audio coverage
11. Sprite assets for all combat stances

## Technical Achievements

### Collision System
- Separation forces prevent character sticking
- Debug tracking for collision analysis
- Smooth physics with immunity frames

### Visual Feedback
- Damage categories with appropriate screen shake
- Color-coded damage numbers for clarity
- Smooth animations for all UI elements

### State Management
- Complex AI state machine for enemy behavior
- Player stance preservation across actions
- Robust cooldown and timing systems

This combat system provides deep tactical gameplay while maintaining accessibility through clear visual feedback and intuitive controls.

## Combat Balance by Defensive State

This section details the complete combat balance divided by the player's defensive state and action state.

### Shield Logic (With Defense Points Available)

#### Stance State (Not Dashing)
**Player in combat stance, not attacking, has defense points remaining**

**Defense Priority Order:**
1. **Defense Points Check**: Same stance as incoming attack
   - Consumes 1 defense point
   - Blocks all damage (0 damage taken)
   - Blue circle expansion visual feedback
   
2. **Perfect Parry Window**: If within 0.5s of entering stance
   - Any losing attack (enemy weaker stance) triggers perfect parry
   - 0 damage to player, enemy becomes stunned for 3 seconds
   - Gold flash and screen shake feedback
   
3. **Final Damage Resolution**:
   - Rock vs Rock: 0 damage (defense point consumed)
   - Paper vs Paper: 0 damage (defense point consumed)  
   - Scissors vs Scissors: 0 damage (defense point consumed)
   - Rock vs Scissors: Perfect parry (0 damage, stun enemy)
   - Paper vs Rock: Perfect parry (0 damage, stun enemy)
   - Scissors vs Paper: Perfect parry (0 damage, stun enemy)
   - Any vs Neutral: 1 damage (75% reduction applied)

#### Dashing State (Attacking)
**Player attacking with defense points, mutual combat scenario**

**Defense Priority Order:**
1. **Defense Points**: Not applicable (both attacking simultaneously)
2. **Perfect Parry**: Not applicable (both attacking simultaneously)
3. **Final Damage Resolution**:
   - Same stance (Rock vs Rock): 0 damage to both
   - Winning stance (Rock vs Scissors): 2 damage to enemy, 0 to player, enemy stunned
   - Losing stance (Scissors vs Rock): 0 damage to enemy, 2 to player, player stunned

### Life Logic (No Defense Points Remaining)

#### Stance State (Not Dashing)  
**Player in combat stance, not attacking, no defense points left**

**Defense Priority Order:**
1. **Defense Points Check**: Same stance as incoming attack
   - No defense points available
   - Defense fails, proceed to parry check
   
2. **Perfect Parry Window**: If within 0.5s of entering stance
   - Any losing attack (enemy weaker stance) triggers perfect parry
   - 0 damage to player, enemy becomes stunned for 3 seconds
   - Gold flash and screen shake feedback
   
3. **Final Damage Resolution**:
   - Rock vs Rock: 1 damage (balanced tie damage)
   - Paper vs Paper: 1 damage (balanced tie damage)
   - Scissors vs Scissors: 1 damage (balanced tie damage)
   - Rock vs Scissors: Perfect parry (0 damage, stun enemy)
   - Paper vs Rock: Perfect parry (0 damage, stun enemy)
   - Scissors vs Paper: Perfect parry (0 damage, stun enemy)
   - Any vs Neutral: 1 damage (75% reduction applied)

#### Dashing State (Attacking)
**Player attacking with no defense points, mutual combat scenario**

**Defense Priority Order:**
1. **Defense Points**: Not applicable (both attacking simultaneously)
2. **Perfect Parry**: Not applicable (both attacking simultaneously)  
3. **Final Damage Resolution**:
   - Same stance (Rock vs Rock): 0 damage to both
   - Winning stance (Rock vs Scissors): 2 damage to enemy, 0 to player, enemy stunned
   - Losing stance (Scissors vs Rock): 0 damage to enemy, 2 to player, player stunned

### Key Balance Differences

**Shield Logic vs Life Logic:**
- **Same Stance Defense**: Shield Logic blocks completely (0 damage), Life Logic takes tie damage (1 damage)
- **Resource Cost**: Shield Logic consumes defense points, Life Logic has no resource cost
- **Strategic Value**: Defense points provide significant tactical advantage

**Stance State vs Dashing State:**
- **Parry Window**: Only available in Stance State (not during mutual attacks)
- **Defense Points**: Only relevant in Stance State vs incoming attacks
- **Damage Scale**: Dashing State uses higher damage values (2 damage for wins) due to mutual combat risk

**Universal Rules Across All States:**
- Perfect parry always provides 0 damage + 3-second enemy stun
- Neutral stance always provides 75% damage reduction (minimum 1 damage)
- Mutual same-stance attacks always result in 0 damage to both parties
- Winning RPS matchups in mutual combat always deal 2 damage + stun loser

## Combat Balance & Testing

### Damage Balance Philosophy
- **Ties should feel like ties**: Same-stance encounters result in minimal damage
- **Defense points are valuable**: Having defense points provides significant advantage
- **Resource management matters**: Running out of defense points has consequences but not devastating

### Balance Changes Made
**v1.1 - Same-Stance Balance Fix**
- **Issue**: Same stance defense without defense points dealt 2 damage (too harsh for a "tie")
- **Fix**: Reduced to 1 damage for better balance
- **Rationale**: Rock vs Rock should never be as punishing as Rock vs Scissors

### Testing Mode Features
- **Enemy Rock-Only Mode**: `debug_rock_only = true` in Enemy.gd
- **Visual Attack Timer**: Progress bar above enemy during attack countdown
- **Purpose**: Perfect timing practice and balance testing

### Quick Reference - Damage Table

| Scenario | With Defense Points | Without Defense Points |
|----------|-------------------|----------------------|
| Same Stance (Rock vs Rock) | 0 damage, -1 defense | 1 damage |
| Winning (Rock vs Scissors) | 2 damage | 2 damage |
| Losing (Scissors vs Rock) | Perfect Parry (0 dmg + stun) | Perfect Parry (0 dmg + stun) |
| vs Neutral | 1 damage | 1 damage |
| Mutual Same Stance | 0 damage | 0 damage |
| Mutual Winner | 2 damage + stun loser | 2 damage + stun loser |

## V2 Combat Balance (Enhanced Defense System)

### Core V2 Changes

**1. Perfect Parry Enhancement**
- Perfect parry now **restores +1 defense point** (capped at maximum 3)
- Maintains original benefits: 0 damage + 3-second enemy stun
- Makes perfect parries more rewarding for resource management

**2. Weak Stance Defense Absorption**
- Defense points can now absorb damage from losing stance matchups
- Priority: Defense points absorb damage before health is affected
- Scales with available defense points (1-2 points can absorb 1-2 damage)

### V2 Combat Balance by Defensive State

#### Shield Logic V2 (With Defense Points Available)

##### Stance State (Not Dashing)
**Player in combat stance, not attacking, has defense points remaining**

**Defense Priority Order:**
1. **Same Stance Defense**: Consumes 1 defense point, blocks all damage
2. **Perfect Parry Window** (0.5s): 
   - 0 damage + stun enemy + **restore 1 defense point**
   - Any losing attack triggers perfect parry
3. **Weak Stance Defense Absorption**:
   - Rock vs Scissors (losing): Defense points absorb up to 2 damage
   - Paper vs Rock (losing): Defense points absorb up to 2 damage  
   - Scissors vs Paper (losing): Defense points absorb up to 2 damage
4. **Final Damage Resolution**:
   - With 2+ defense points vs weak stance: 0 health damage, -2 defense points
   - With 1 defense point vs weak stance: 0 health damage, -1 defense point
   - With 0 defense points vs weak stance: 2 health damage
   - Any vs Neutral: 1 health damage (75% reduction)

##### Dashing State (Attacking)
**Player attacking with defense points, mutual combat scenario**

**V2 Mechanics:**
- Defense points and parry windows not applicable (mutual attack)
- Same damage resolution as V1 (no changes to mutual combat)
- Perfect parry restoration only applies to defensive scenarios

**Damage Resolution:**
- Same stance: 0 damage to both
- Winning stance: 2 damage to enemy, 0 to player, enemy stunned
- Losing stance: 0 damage to enemy, 2 to player, player stunned

#### Life Logic V2 (No Defense Points Remaining)

##### Stance State (Not Dashing)
**Player in combat stance, not attacking, no defense points left**

**Defense Priority Order:**
1. **Same Stance Defense**: No defense points available, defense fails
2. **Perfect Parry Window** (0.5s):
   - 0 damage + stun enemy + **restore 1 defense point**
   - Provides path back to Shield Logic state
3. **Weak Stance Defense Absorption**: Not available (no defense points)
4. **Final Damage Resolution**:
   - Same stance: 1 health damage (balanced tie)
   - Weak stance: 2 health damage (full damage)
   - Any vs Neutral: 1 health damage (75% reduction)

##### Dashing State (Attacking)
**Player attacking with no defense points, mutual combat scenario**

**V2 Mechanics:**
- Identical to V1 (no changes to mutual combat)
- Defense points and parry windows not applicable

**Damage Resolution:**
- Same stance: 0 damage to both
- Winning stance: 2 damage to enemy, 0 to player, enemy stunned
- Losing stance: 0 damage to enemy, 2 to player, player stunned

### V2 Strategic Implications

**Enhanced Resource Management:**
- Defense points now provide protection against all damage types
- Perfect parries become crucial for resource sustainability
- Weak stance positions are less punishing but still costly

**Risk vs Reward Balance:**
- Perfect parry timing becomes more valuable (restores resources)
- Players can afford to be more aggressive knowing defense points absorb weak stance damage
- Resource depletion still creates meaningful tactical pressure

**Combat Flow Improvements:**
- Smoother transition between Shield Logic and Life Logic states
- Perfect parries provide comeback opportunities
- Defense points feel more valuable and strategic

### V2 Damage Comparison Tables

#### Weak Stance Scenarios (Enemy Stronger)

| Player Defense Points | V1 Damage | V2 Damage | V2 Defense Points Lost |
|---------------------|-----------|-----------|----------------------|
| 3 defense points | 2 health | 0 health | 2 defense points |
| 2 defense points | 2 health | 0 health | 2 defense points |
| 1 defense point | 2 health | 0 health | 1 defense point |
| 0 defense points | 2 health | 2 health | 0 defense points |

#### Perfect Parry Scenarios

| Scenario | V1 Result | V2 Result |
|----------|-----------|-----------|
| Perfect Parry Success | 0 damage + stun enemy | 0 damage + stun enemy + restore 1 defense point |
| Perfect Parry with 0 defense | Creates comeback opportunity | Creates comeback opportunity + gives 1 defense point |
| Perfect Parry with 3 defense | Same as V1 | Still capped at 3 defense points maximum |

### V2 Implementation Details

**New Functions Added:**
- `Player.restore_defense_point()` - Restores 1 defense point (capped at max)
- `Player.consume_multiple_defense_points(amount)` - Consumes multiple defense points
- Enhanced `perfect_parry_success()` - Now calls restore_defense_point()

**Modified Combat Logic:**
- `Enemy.calculate_combat_damage()` - Added weak_stance_damage flag
- Enhanced damage application logic for defense point absorption
- Maintains backward compatibility with existing systems

**UI Integration:**
- Existing defense point UI automatically reflects changes
- Uses established `defense_points_changed` signal system
- No additional UI changes required

## Collision System Debugging Lessons

This section documents critical lessons learned from debugging collision detection issues in the combat system.

### Problem: Enemy Hits From Too Far Away

**Initial Issue:**
- Enemy was hitting player from 100px away instead of the expected 7.5px collision range
- Player couldn't be hit at all after switching to proper collision detection

**Root Causes Discovered:**

#### 1. Wrong Collision Detection Method
**Problem**: Using manual distance calculation instead of Godot's collision system
```gdscript
# ❌ WRONG - Manual distance check
var distance = global_position.distance_to(player_ref.global_position)
if distance <= attack_range:  # attack_range = 100.0

# ✅ CORRECT - Use Godot's collision system
var bodies = attack_area.get_overlapping_bodies()
for body in bodies:
    if body is Player:
```

**Lesson**: Always use `Area2D.get_overlapping_bodies()` instead of manual distance calculations for accurate collision detection.

#### 2. Missing Collision Layers/Masks
**Problem**: Area2D nodes couldn't detect CharacterBody2D nodes because collision layers weren't configured

**Solution Applied:**
```
Player CharacterBody2D: collision_layer = 1
Enemy CharacterBody2D: collision_layer = 2
Enemy AttackArea: collision_mask = 1 (detects Player on layer 1)
Player AttackArea: collision_mask = 2 (detects Enemy on layer 2)
```

**Lesson**: 
- **Collision Layer**: What layer an object EXISTS on
- **Collision Mask**: What layers an object can DETECT
- Area2D nodes require proper collision_mask to detect bodies on specific layers

#### 3. Scale vs Effective Collision Size
**Problem**: CollisionShape2D had scale 0.3, making effective radius microscopic

**Scale Impact:**
- Base shape radius: 25.0px
- With scale 0.3: 25.0 × 0.3 = 7.5px effective radius  
- With scale 1.0: 25.0 × 1.0 = 25.0px effective radius

**Lesson**: Always calculate effective collision size as `base_size × scale`. Visual sprite size ≠ collision size.

#### 4. Collision Size Balance
**Current Working Setup:**
- **Player Body**: 12×12 rectangle (precise movement collision)
- **Player Attack**: 22px circle radius (generous attack range)
- **Enemy Body**: 26×21 rectangle (precise movement collision)  
- **Enemy Attack**: 25px circle radius (matches player attack range)

**Lesson**: Attack collision areas should be slightly larger than body collision areas for reliable hit detection.

### Debugging Methodology That Worked

#### 1. Comprehensive Logging
```gdscript
# Log collision area properties
var bodies = attack_area.get_overlapping_bodies()
print("Bodies found in attack_area: ", bodies.size())
for body in bodies:
    print("Body: ", body.name, " at ", body.global_position)

# Log effective collision sizes  
var effective_radius = shape.radius * collision_shape.scale.x
print("Effective attack radius: ", effective_radius, "px")
```

#### 2. Visual Debugging
- Enabled `get_tree().debug_collisions_hint = true` to see collision shapes
- Added colored sprite modulation during attacks for visibility
- Used console output to track exactly what was/wasn't being detected

#### 3. Layer/Mask Verification
```gdscript
print("Enemy collision_layer: ", collision_layer)
print("Enemy attack_area collision_mask: ", attack_area.collision_mask)
```

### Key Technical Lessons

1. **Use Godot's Built-in Systems**: `get_overlapping_bodies()` is more reliable than manual distance checks
2. **Collision Layers Are Essential**: Area2D detection requires proper layer/mask configuration
3. **Scale Affects Everything**: Always multiply base collision size by scale for true effective size
4. **Size Balance Matters**: Attack areas need appropriate sizing relative to body collision areas
5. **Debug Systematically**: Log collision properties, visualize shapes, verify layer setup

### Fixed Implementation

**Scene Setup (.tscn files):**
```
Player CharacterBody2D:
  collision_layer = 1
  CollisionShape2D: RectangleShape2D size=(12,12)
  AttackArea Area2D:
    collision_mask = 2
    CollisionShape2D: CircleShape2D radius=22.0

Enemy CharacterBody2D:
  collision_layer = 2  
  CollisionShape2D: RectangleShape2D size=(26,21)
  AttackArea Area2D:
    collision_mask = 1
    CollisionShape2D: CircleShape2D radius=25.0, scale=(1.0,1.0)
```

**Code Implementation:**
```gdscript
func attack_during_dash():
    var bodies = attack_area.get_overlapping_bodies()
    for body in bodies:
        if body is Player and not body in players_hit_this_dash:
            # Process hit with proper collision detection
```

This collision system now provides pixel-perfect accuracy matching the visual representation.