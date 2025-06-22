# Game Variables Reference

This document contains all tweakable gameplay variables that can be modified by items, difficulty settings, or balance adjustments. Visual and audio variables are excluded as they remain constant.

## Player Combat Variables

### Health & Defense System
```gdscript
# Player.gd
max_health: int = 5                    # Maximum health points
current_health: int = 5               # Starting health 
max_defense_points: int = 3           # Maximum defense points
current_defense_points: int = 3       # Starting defense points
```

**Item Modification Potential:**
- Health items: Increase max_health (Heart Container +1 HP)
- Defense items: Increase max_defense_points (Shield Upgrade +1 DP)
- Starting bonuses: Modify current values for battle start

### Combat Timing
```gdscript
# Player.gd
attack_cooldown: float = 1.0          # Seconds between attacks
parry_window_duration: float = 0.5    # Perfect parry window duration
stun_duration: float = 3.0            # Stun duration when parried
immunity_duration: float = 0.5        # Immunity frames after taking damage
```

**Item Modification Potential:**
- Attack Speed items: Reduce attack_cooldown (Quick Draw -20% cooldown)
- Parry items: Increase parry_window_duration (Focus Ring +0.2s window)
- Resilience items: Reduce stun_duration (Iron Will -1s stun)
- Defense items: Increase immunity_duration (Tough Skin +0.2s immunity)

### Damage Values
```gdscript
# Combat Logic (calculated in damage functions)
neutral_stance_damage: int = 1        # Damage vs neutral stance
winning_stance_damage: int = 2        # Damage when winning RPS matchup
tie_stance_damage: int = 1            # Damage on same stance (no defense points)
perfect_parry_damage: int = 0         # Damage when perfect parry succeeds
```

**Item Modification Potential:**
- Damage items: Increase all damage values (Power Glove +1 all damage)
- Tactical items: Modify specific scenarios (Neutral Breaker +1 vs neutral)
- Balance items: Reduce damage taken (Armor -1 damage taken)

### Defense Point Mechanics
```gdscript
# Player.gd
defense_points_per_perfect_parry: int = 1  # Defense points restored on perfect parry
```

**Item Modification Potential:**
- Parry Mastery: Increase restoration (Master Parry +2 points per perfect parry)
- Defense Efficiency: Modify consumption rates

## Player Movement Variables

### Movement Speeds
```gdscript
# Player.gd
speed: float = 200.0                  # Base walking speed (pixels/second)
acceleration: float = 800.0           # Acceleration rate (pixels/second²)
deceleration: float = 1000.0          # Deceleration rate (pixels/second²)
movement_threshold: float = 10.0      # Minimum velocity for walking animation
```

**Item Modification Potential:**
- Speed items: Increase speed (Swift Boots +40 speed)
- Agility items: Increase acceleration/deceleration (Quick Start +200 accel)
- Momentum items: Modify movement feel and responsiveness

### Dash Attack System
```gdscript
# Player.gd
dash_speed: float = 600.0             # Speed during dash attack (pixels/second)
dash_duration: float = 0.3            # Duration of dash attack (seconds)
```

**Item Modification Potential:**
- Dash items: Increase dash_speed (Dash Boost +100 speed)
- Range items: Increase dash_duration (Extended Dash +0.1s duration)
- Tactical items: Multiple dashes or dash cooldown reduction

## Enemy Variables

### Enemy Health & Defense
```gdscript
# Enemy.gd
max_health: int = 5                   # Enemy maximum health
current_health: int = 5               # Enemy starting health
max_defense_points: int = 1           # Enemy maximum defense points
current_defense_points: int = 1       # Enemy starting defense points
```

**Item Modification Potential:**
- Difficulty items: Modify enemy health (Challenge Mode +2 enemy HP)
- Tactical items: Affect enemy defense (Armor Piercing -1 enemy defense)

### Enemy Movement & AI
```gdscript
# Enemy.gd
speed: float = 100.0                  # Enemy base movement speed
detection_range: float = 150.0        # Base detection radius (pixels)
enhanced_detection_radius: float = 300.0  # Enhanced detection when spotted
attack_range: float = 100.0           # Attack decision range (not collision)
```

**Item Modification Potential:**
- Stealth items: Reduce detection_range (Stealth Cloak -50 detection)
- Awareness items: Modify AI reaction ranges
- Difficulty items: Increase enemy speeds (Hard Mode +50 enemy speed)

### Enemy Combat Parameters
```gdscript
# Enemy.gd
dash_speed: float = 300.0             # Enemy dash attack speed (half of player)
dash_duration: float = 0.6            # Enemy dash duration (double of player)
attack_cooldown: float = 1.2          # Enemy attack cooldown (slightly longer than player)
stun_duration: float = 3.0            # Enemy stun duration (same as player)
```

**Item Modification Potential:**
- Difficulty items: Modify enemy attack patterns (Aggressive AI -0.3s cooldown)
- Balance items: Affect enemy combat effectiveness

### Enemy AI Timing
```gdscript
# Enemy.gd
stance_to_dash_delay: float = 1.0     # Delay between stance selection and attack
stance_decision_timer: float = 0.3    # Time to decide on stance
positioning_timer: float = 1.0-2.0   # Time spent positioning (random range)
retreat_timer: float = 1.0           # Time spent retreating after attack
```

**Item Modification Potential:**
- AI Manipulation items: Increase reaction delays (Confusion Aura +0.5s delays)
- Pressure items: Reduce enemy thinking time (Intimidation -0.2s decisions)

## Global Combat Variables

### Damage Multipliers
```gdscript
# Future implementation
player_damage_multiplier: float = 1.0     # Multiplier for all player damage output
enemy_damage_multiplier: float = 1.0      # Multiplier for all enemy damage output (difficulty scaling)
defense_effectiveness: float = 1.0        # Multiplier for defense point effectiveness
```

**Item Modification Potential:**
- Power items: Increase player_damage_multiplier (Berserker Mode +0.5x damage)
- Difficulty items: Increase enemy_damage_multiplier (Hard Mode +0.3x enemy damage)
- Defensive items: Increase defense_effectiveness (Master Shield +0.2x defense)

### Collision & Range Variables
```gdscript
# Scene Configuration (.tscn files)
player_attack_radius: float = 22.0        # Player attack collision radius (pixels)
enemy_attack_radius: float = 25.0         # Enemy attack collision radius (pixels)
player_body_collision: Vector2 = (12, 12) # Player movement collision size
enemy_body_collision: Vector2 = (26, 21)  # Enemy movement collision size
```

**Item Modification Potential:**
- Range items: Increase attack radii (Long Reach +5 attack radius)
- Size items: Modify collision boxes for gameplay variety
- Precision items: Adjust collision balance for different playstyles

## Future Expansion Variables

### Combo System (Not Yet Implemented)
```gdscript
# Future implementation
max_consecutive_attacks: int = 3           # Max attacks before forced cooldown
combo_damage_bonus: float = 0.1           # Damage bonus per consecutive hit
combo_decay_time: float = 2.0             # Time before combo resets
```

**Item Modification Potential:**
- Combo items: Increase max_consecutive_attacks (Chain Fighter +2 max combo)
- Damage items: Increase combo_damage_bonus (Momentum +0.05 per hit)

### Environmental Variables (Future)
```gdscript
# Future implementation
room_size_multiplier: float = 1.0          # Multiplier for room boundaries
environmental_hazard_damage: int = 1      # Damage from stage hazards
boundary_push_force: float = 50.0         # Force applied at room edges
```

**Item Modification Potential:**
- Environment items: Modify room interaction (Wall Walker - immunity to boundaries)
- Hazard items: Reduce environmental damage (Thick Boots -1 hazard damage)

## Derived Values (Calculated)

### Effective Ranges
```gdscript
# Calculated at runtime
player_dash_distance = dash_speed * dash_duration  # 600 * 0.3 = 180 pixels
enemy_dash_distance = dash_speed * dash_duration   # 300 * 0.6 = 180 pixels
effective_attack_range = attack_radius + body_size # Actual hit detection range
```

### Combat Effectiveness
```gdscript
# Calculated based on multiple variables
attacks_per_second = 1.0 / attack_cooldown         # Attack frequency
movement_responsiveness = acceleration / speed      # Movement feel factor
survival_rating = (health + defense_points) * immunity_duration  # Survivability
```

## Variable Categories for Item Design

### **Offensive Items**
- Damage multipliers, attack speed, dash range, combo potential

### **Defensive Items** 
- Health, defense points, immunity frames, parry windows

### **Mobility Items**
- Movement speed, acceleration, dash speed/duration

### **Tactical Items**
- AI manipulation, detection ranges, cooldown modifications

### **Difficulty Items**
- Enemy stat modifications, global damage multipliers

### **Specialized Items**
- Unique mechanics that don't fit standard categories

## Implementation Notes

### Current Variable Access
- Most variables are `@export` in their respective scripts for easy modification
- Scene files (.tscn) contain collision and structural values
- Combat logic calculations use these base values with situational modifiers

### Future Item System Integration
- Items should modify these base values through multipliers or additions
- Temporary effects should store original values for restoration
- Stacking items should use appropriate combination methods (additive vs multiplicative)

### Balance Considerations
- Movement speed changes affect combat timing significantly
- Parry window modifications have major tactical implications  
- Enemy AI modifications can dramatically change difficulty curve
- Health/defense changes affect entire game balance

This variable system provides comprehensive coverage for future item systems, difficulty scaling, and gameplay variety while maintaining clear organization and modification potential.