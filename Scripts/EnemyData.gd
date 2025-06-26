class_name EnemyData
extends Resource

## Enemy Data Resource
## Configurable enemy parameters for creating different enemy variants
## Used by Enemy.gd to load enemy characteristics from .tres files

# === BASIC STATS ===
@export_group("Basic Stats")
@export var enemy_name: String = "Basic Enemy"
@export var max_health: int = 5
@export var max_defense_points: int = 1

# === MOVEMENT & SPEED ===
@export_group("Movement")
@export var speed: float = 100.0
@export var dash_speed: float = 300.0
@export var dash_duration: float = 0.6

# === DETECTION SYSTEM ===
@export_group("Detection")
enum DetectionType { VISION, AUTOMATIC, PROXIMITY }
@export var detection_type: DetectionType = DetectionType.VISION
@export var instant_detection: bool = false  # Skip vision, detect immediately when player enters room
@export var detection_radius: float = 500.0  # Range for instant detection (room-wide)
@export var detection_range: float = 40.0
@export var enhanced_detection_radius: float = 80.0
@export var vision_angle: float = 60.0  # degrees (for vision-based detection)
@export var vision_range: float = 50.0  # pixels (for vision-based detection)
@export var vision_collision_mask: int = 2  # Which layers block vision (walls/obstacles)

# === COMBAT BEHAVIOR ===
@export_group("Combat")
@export var attack_cooldown: float = 1.2
@export var attack_range: float = 100.0  # Decision range, not collision
@export var damage_multiplier: float = 1.0
@export var stun_duration: float = 3.0

# === STANCE PROBABILITIES ===
@export_group("Stance Behavior")
## Probability weights for stance selection (Neutral, Rock, Paper, Scissors)
## Higher values = more likely to choose that stance
@export var neutral_probability: float = 25.0
@export var rock_probability: float = 25.0
@export var paper_probability: float = 25.0
@export var scissors_probability: float = 25.0

# === AI TIMING ===
@export_group("AI Timing")
@export var stance_to_dash_delay: float = 1.0
@export var stance_decision_timer: float = 0.3
@export var positioning_timer_min: float = 1.0
@export var positioning_timer_max: float = 2.0
@export var retreat_timer: float = 1.0
@export var idle_duration: float = 3.0  # Fixed duration for idle animation (seconds)
@export var aggression_level: float = 1.0  # Multiplier for timing (higher = faster)

# === REACTIVE AI (Future) ===
@export_group("Advanced AI")
@export var can_react: bool = false  # Can counter-attack mid-combat
@export var reaction_chance: float = 0.5  # Probability of reacting to player attacks
@export var reaction_time: float = 1.0  # Time window for reaction
@export var reflex: float = 0.0  # Future: Reflex speed modifier
@export var weight: float = 1.0  # Future: Weight/mass for physics

# === VISUAL SYSTEM ===
@export_group("Visual")
@export var sprite_texture_path: String = "res://assets/test_sprites/idle_enemy.png"
@export var sprite_scale: Vector2 = Vector2(1.0, 1.0)
@export var color_tint: Color = Color.WHITE

# === COLLISION & SIZE ===
@export_group("Collision")
@export var body_collision_size: Vector2 = Vector2(26, 21)
@export var attack_radius: float = 25.0
@export var attack_collision_scale: Vector2 = Vector2(1.0, 1.0)

# === HELPER FUNCTIONS ===

func get_stance_probabilities() -> Array[float]:
	"""Returns array of stance probabilities for weighted selection"""
	return [neutral_probability, rock_probability, paper_probability, scissors_probability]

func get_total_probability() -> float:
	"""Returns sum of all stance probabilities for normalization"""
	return neutral_probability + rock_probability + paper_probability + scissors_probability

func get_normalized_probabilities() -> Array[float]:
	"""Returns probabilities normalized to sum to 100%"""
	var total = get_total_probability()
	if total <= 0:
		return [25.0, 25.0, 25.0, 25.0]  # Default equal distribution
	
	var factor = 100.0 / total
	return [
		neutral_probability * factor,
		rock_probability * factor,
		paper_probability * factor,
		scissors_probability * factor
	]

func get_aggression_modified_timer(base_timer: float) -> float:
	"""Apply aggression level to timing values"""
	return base_timer / aggression_level

func validate_data() -> bool:
	"""Validate that all data values are reasonable"""
	var valid = true
	
	# Check basic stats
	if max_health <= 0 or max_defense_points < 0:
		print("Warning: Invalid health/defense values in ", enemy_name)
		valid = false
	
	# Check movement values
	if speed <= 0 or dash_speed <= 0 or dash_duration <= 0:
		print("Warning: Invalid movement values in ", enemy_name)
		valid = false
	
	# Check detection values
	if detection_range <= 0 or vision_range <= 0:
		print("Warning: Invalid detection values in ", enemy_name)
		valid = false
	
	# Check probabilities
	if get_total_probability() <= 0:
		print("Warning: All stance probabilities are 0 in ", enemy_name)
		valid = false
	
	return valid

func get_archetype_description() -> String:
	"""Generate description of enemy archetype based on probabilities"""
	var probs = get_normalized_probabilities()
	var max_prob = probs.max()
	var max_index = probs.find(max_prob)
	
	var descriptions = [
		"Passive (prefers neutral)",
		"Aggressive (rock-heavy)",
		"Defensive (paper-heavy)",
		"Unpredictable (scissors-heavy)"
	]
	
	if max_prob > 40.0:
		return descriptions[max_index]
	else:
		return "Balanced (mixed tactics)"