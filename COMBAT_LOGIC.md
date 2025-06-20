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