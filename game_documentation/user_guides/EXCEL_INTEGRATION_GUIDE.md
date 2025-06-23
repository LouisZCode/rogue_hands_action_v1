# 📊 Enemy Excel Integration Guide

## Overview
The enemy resource system now supports Excel/CSV integration for easy enemy creation and management without touching code!

## 🚀 Quick Start

### Step 1: Export Current Enemies
- **In-Game**: Press `Page Up` to export current enemies to CSV
- **Manual**: The system auto-exports on startup to `enemy_database.csv`

### Step 2: Edit in Excel
- Open `enemy_database.csv` in Excel or Google Sheets
- Modify enemy stats, add new rows for new enemies
- Save as CSV format

### Step 3: Import Back to Game
- **In-Game**: Press `Page Down` to get database stats
- **Code**: Call `EnemyDatabaseManager.update_from_csv()` function
- Resources automatically regenerate from your Excel data!

## 📋 CSV Column Reference

### Basic Stats
- `enemy_name`: Display name (e.g., "Rock Tank Enemy")
- `max_health`: Health points (1-20 typical range)
- `max_defense_points`: Defense shields (0-5 typical range)

### Movement
- `speed`: Walking speed (50-200 typical range)
- `dash_speed`: Attack dash speed (200-600 typical range)  
- `dash_duration`: How long dash lasts (0.2-1.2 seconds)

### Detection System
- `instant_detection`: true/false - Skip vision system, detect immediately
- `detection_radius`: Range for instant detection (300-800 pixels)
- `vision_angle`: Field of view in degrees (60-120 typical)
- `vision_range`: Vision distance (150-300 pixels)

### Visual Customization
- `sprite_texture_path`: Path to sprite (e.g., "res://assets/test_sprites/rock_enemy.png")
- `sprite_scale`: Size as "x|y" format (e.g., "0.25|0.25")
- `color_tint`: Color as "r|g|b|a" format (e.g., "0.8|0.3|0.3|1")

### Combat Behavior
- `attack_cooldown`: Seconds between attacks (0.5-3.0 typical)
- `attack_range`: Decision distance for attacks (50-150 pixels)
- `damage_multiplier`: Damage scaling (0.5-2.0 typical)

### Stance Probabilities (0-100, should total ~100)
- `neutral_probability`: Defensive stance weight
- `rock_probability`: Rock stance weight  
- `paper_probability`: Paper stance weight
- `scissors_probability`: Scissors stance weight

### AI Timing
- `aggression_level`: Speed multiplier (0.5-3.0, higher = faster AI)
- `stance_to_dash_delay`: Delay before attacking (0.3-2.0 seconds)
- `retreat_timer`: How long to retreat after losing (0.5-2.0 seconds)

### Physical Properties
- `body_collision_size`: Hitbox as "width|height" (e.g., "26|21")
- `attack_radius`: Attack area size (15-40 pixels typical)
- `attack_collision_scale`: Attack area scaling as "x|y" (e.g., "1.2|1.2")

## 🎯 Enemy Archetype Templates

### Tank Enemy
```
High health (8-12), low speed (60-80), instant detection
High rock probability (50-70%), larger collision size
Red color tint, larger sprite scale (0.25-0.3)
```

### Scout Enemy  
```
Low health (2-4), high speed (140-200), instant detection
High scissor probability (50-70%), smaller collision size
Orange/yellow color tint, smaller sprite scale (0.15-0.18)
```

### Defensive Enemy
```
Medium health (5-7), medium speed (90-120), vision detection
High paper probability (50-70%), wide vision angle (100-140°)
Blue color tint, standard sprite scale (0.19-0.22)
```

### Elite Enemy
```
Very high health (10-15), variable speed, enhanced abilities
Balanced or specialized stance probabilities
High damage multiplier (1.5-2.5), special color tints
```

## 🔧 Development Controls

### In-Game Debug Keys (Development Build Only)
- **Page Up**: Export current enemies to CSV
- **Page Down**: Show database statistics  
- **Home**: Create test database with example enemies

### Programmatic Usage
```gdscript
# Export current resources
EnemyDatabaseManager.export_enemies_to_csv()

# Import from edited CSV
EnemyDatabaseManager.update_from_csv("res://my_enemies.csv")

# Validate CSV format
var report = EnemyResourceGenerator.validate_csv_format("res://enemies.csv")

# Get database statistics
EnemyDatabaseManager.get_database_stats()
```

## 📈 Workflow Example

1. **Initial Setup**: Game auto-exports current 4 enemies to `enemy_database.csv`
2. **Excel Editing**: Open CSV in Excel, duplicate "Rock Tank Enemy" row
3. **Customization**: Change name to "Mega Rock Boss", increase health to 15, etc.
4. **Save**: Save Excel file as CSV format  
5. **Import**: Use debug key or call update function to regenerate resources
6. **Test**: New "Mega Rock Boss" now spawns randomly in game!

## ✅ Validation & Error Handling

The system includes comprehensive validation:
- **Required Fields**: Ensures critical columns exist
- **Type Checking**: Validates numeric ranges and boolean values
- **Format Checking**: Verifies Vector2 and Color format strings
- **Resource Validation**: Checks sprite paths and collision values

Errors are reported in console with specific row and column information.

## 🚀 Advanced Features

- **Batch Creation**: Create 20+ enemies in Excel, import all at once
- **Version Control**: Keep CSV files in git for enemy balance history
- **Team Collaboration**: Share Excel files between designers and programmers
- **Rapid Iteration**: Tweak stats in Excel, test immediately in game
- **Data Analysis**: Use Excel charts to visualize enemy balance curves

This system enables content creators to manage unlimited enemy varieties without touching any code! 🎮