# 🔥 **EXCEL ENEMY EDITOR - COMPLETE GUIDE** 🔥

## 🚀 **GET STARTED IN 2 MINUTES!**

### **Step 1: Get Your Current Enemies**
1. **Start the game** (this auto-exports your enemies to `enemy_database.csv`)
2. **Or press Page Up** while in-game to manually export
3. **Find the file**: `enemy_database.csv` in your project folder

### **Step 2: Open in Excel/Google Sheets**
1. **Open Excel** → Open → Select `enemy_database.csv`
2. **Or Google Sheets** → File → Import → Upload CSV
3. **You'll see your enemies in a spreadsheet!** 📊

### **Step 3: Edit & Create Enemies**
1. **Modify existing rows** to change enemy stats
2. **Copy & paste rows** to create variants quickly
3. **Add new rows** for completely new enemies
4. **Save as CSV format** (important!)

### **Step 4: Import Back to Game**
1. **Press Page Down** in-game to import your changes
2. **Watch console** for "✅ Successfully updated X enemy resources"
3. **Test immediately** - new enemies spawn randomly!

---

## 📊 **COLUMN REFERENCE - EXCEL FRIENDLY!**

### **🏷️ BASIC ENEMY INFO**
| Column | Range | Description | Example |
|--------|-------|-------------|---------|
| `enemy_name` | Text | Display name | "Fire Demon" |
| `max_health` | 1-20 | Health points | 8 |
| `max_defense_points` | 0-5 | Shield count | 2 |

### **🏃 MOVEMENT & SPEED**
| Column | Range | Description | Example |
|--------|-------|-------------|---------|
| `speed` | 50-200 | Walking speed | 120 |
| `dash_speed` | 200-600 | Attack speed | 400 |
| `dash_duration` | 0.2-1.5 | Attack duration (seconds) | 0.6 |

### **👁️ DETECTION SYSTEM**
| Column | Range | Description | Example |
|--------|-------|-------------|---------|
| `instant_detection` | true/false | Skip vision, attack immediately | true |
| `detection_radius` | 300-800 | Instant detection range | 500 |
| `vision_angle` | 60-180 | Field of view (degrees) | 90 |
| `vision_range` | 100-400 | Vision distance | 250 |

### **🎨 VISUAL CUSTOMIZATION**
| Column | Range | Description | Example |
|--------|-------|-------------|---------|
| `sprite_texture_path` | Path | Sprite file location | `res://assets/test_sprites/rock_enemy.png` |
| `sprite_scale_x` | 0.1-0.4 | Horizontal size | 0.25 |
| `sprite_scale_y` | 0.1-0.4 | Vertical size | 0.25 |
| `color_red` | 0-2 | Red tint (1=normal) | 0.8 |
| `color_green` | 0-2 | Green tint (1=normal) | 0.3 |
| `color_blue` | 0-2 | Blue tint (1=normal) | 0.3 |
| `color_alpha` | 0-1 | Transparency (1=solid) | 1 |

### **⚔️ COMBAT BEHAVIOR**
| Column | Range | Description | Example |
|--------|-------|-------------|---------|
| `attack_cooldown` | 0.5-3 | Seconds between attacks | 1.2 |
| `attack_range` | 50-200 | Attack decision distance | 100 |
| `damage_multiplier` | 0.5-3 | Damage scaling | 1.5 |

### **🎯 STANCE PROBABILITIES** (Should total ~100)
| Column | Range | Description | Example |
|--------|-------|-------------|---------|
| `neutral_probability` | 0-100 | Defensive stance weight | 20 |
| `rock_probability` | 0-100 | Rock stance weight | 60 |
| `paper_probability` | 0-100 | Paper stance weight | 15 |
| `scissors_probability` | 0-100 | Scissors stance weight | 5 |

### **🤖 AI TIMING**
| Column | Range | Description | Example |
|--------|-------|-------------|---------|
| `aggression_level` | 0.3-3 | AI speed multiplier (higher=faster) | 1.5 |
| `stance_to_dash_delay` | 0.3-2 | Attack delay (seconds) | 0.8 |

---

## 🎮 **QUICK ENEMY CREATION RECIPES**

### **🛡️ TANK ENEMY** (Slow, High Health)
```
health: 10-15, speed: 60-80, instant_detection: true
rock_probability: 60-80, color: red tint (0.8, 0.3, 0.3)
sprite_scale: 0.25-0.3 (larger), attack_cooldown: 2.0+ (slower)
```

### **⚡ SCOUT ENEMY** (Fast, Low Health)
```
health: 2-4, speed: 150-200, instant_detection: true
scissors_probability: 60-80, color: orange tint (1, 0.6, 0.2)
sprite_scale: 0.15-0.18 (smaller), attack_cooldown: 0.6-0.8 (faster)
```

### **🛡️ DEFENSIVE ENEMY** (Balanced, Vision-Based)
```
health: 5-7, speed: 100-120, instant_detection: false
paper_probability: 50-70, vision_angle: 120+ (wide vision)
color: blue tint (0.4, 0.7, 1), defense_points: 2-3
```

### **👑 BOSS ENEMY** (High Everything)
```
health: 15-20, defense_points: 3-4, damage_multiplier: 2-3
sprite_scale: 0.3+ (huge), color: purple tint (0.8, 0.2, 0.8)
can_react: true, reaction_chance: 0.8+ (smart AI)
```

### **🥷 ASSASSIN ENEMY** (Stealth + High Damage)
```
health: 3-5, speed: 130+, instant_detection: false
vision_angle: 180 (sees everything), damage_multiplier: 2+
color: dark tint (0.3, 0.3, 0.3, 0.8), scissors_probability: 70+
```

---

## 💡 **PRO EXCEL TIPS**

### **🔥 RAPID ENEMY CREATION**
1. **Select entire row** of existing enemy → Copy
2. **Paste below** → Change name and 2-3 key stats
3. **Instant new enemy variant!**

### **📊 BALANCE ANALYSIS**
1. **Select health column** → Insert Chart → Line Chart
2. **View enemy power progression** visually
3. **Adjust outliers** for better balance

### **🎨 COLOR COORDINATION**
1. **Use Excel color cells** to preview tints
2. **Red enemies**: `color_red: 1, color_green: 0.3, color_blue: 0.3`
3. **Blue enemies**: `color_red: 0.3, color_green: 0.7, color_blue: 1`
4. **Green enemies**: `color_red: 0.3, color_green: 1, color_blue: 0.3`

### **⚡ BULK EDITING**
1. **Select multiple cells** in same column
2. **Type new value** → Ctrl+Shift+Enter
3. **All selected cells updated at once!**

---

## 🔧 **TESTING & VALIDATION**

### **✅ QUICK VALIDATION CHECKLIST**
- [ ] Enemy name is unique
- [ ] Health between 1-20
- [ ] Speed between 50-200
- [ ] Stance probabilities total ~100
- [ ] Sprite path exists in assets folder
- [ ] Color values between 0-2

### **🐛 COMMON ISSUES**
| Problem | Solution |
|---------|----------|
| "Parse error" | Check for empty cells, use 0 instead |
| "Invalid sprite" | Verify path starts with `res://assets/` |
| Enemy too fast/slow | Check speed AND dash_speed values |
| Wrong colors | Verify color values are 0-2, alpha is 0-1 |
| Stance issues | Ensure probabilities total around 100 |

### **🧪 TESTING WORKFLOW**
1. **Save CSV** with small changes first
2. **Import to game** → Press Page Down
3. **Fight new enemy** to test balance
4. **Iterate quickly** in Excel
5. **Repeat until perfect!**

---

## 🏆 **ADVANCED FEATURES**

### **📈 DIFFICULTY CURVES**
Use Excel formulas for automatic progression:
```
Row 2: =B1*1.1    (10% health increase each row)
Row 3: =B2*1.1    (Copy down for auto-scaling)
```

### **🎲 RANDOM GENERATION**
Use Excel RAND() functions:
```
=RANDBETWEEN(50,150)     (Random speed 50-150)
=RAND()*50+25           (Random probability 25-75)
```

### **🔍 FILTERING & SORTING**
1. **Select all data** → Data → Filter
2. **Filter by type** (Tank, Scout, etc.)
3. **Sort by health** to see power progression
4. **Find gaps** in balance easily

### **💾 VERSION CONTROL**
1. **Save dated copies**: `enemies_v1.1.csv`, `enemies_v1.2.csv`
2. **Track balance changes** over time
3. **Revert to previous versions** easily

---

## 🎯 **EXAMPLE WORKFLOWS**

### **🔥 CREATE FIRE LEVEL ENEMIES**
1. Copy existing enemies → Change names to "Fire Warrior", "Fire Mage", etc.
2. Set all `color_red` to 1.2-1.5 (bright red/orange)
3. Increase `damage_multiplier` by 0.3 (fire does more damage)
4. Import → Test → Adjust heat level! 🔥

### **❄️ CREATE ICE LEVEL ENEMIES**
1. Copy enemies → Names to "Ice Guardian", "Frost Scout", etc.
2. Set `color_blue` to 1.3, others to 0.6 (icy blue)
3. Reduce `speed` by 20% (ice slows them down)
4. Increase `defense_points` by 1 (ice armor)

### **⚡ CREATE BOSS RUSH**
1. Copy 4 different archetypes
2. Multiply `health` by 2-3x
3. Set `sprite_scale` to 0.35+ (massive)
4. Increase `damage_multiplier` to 2+
5. Epic boss battles ready!

---

## 🎮 **GET CREATIVE!**

The system supports **unlimited enemy types**! Try:
- **🦇 Vampire enemies** (high health regen via can_react)
- **🏃 Speed demons** (200+ speed, low health)
- **🛡️ Paladin enemies** (high defense, slow attacks)
- **🎭 Mimic enemies** (balanced stats, random behavior)
- **👻 Ghost enemies** (low alpha, high speed)

**Your imagination is the only limit!** 🚀

---

*💡 Pro Tip: Start with small changes, test frequently, and build up your enemy army gradually. The system is designed to handle hundreds of enemy types!*