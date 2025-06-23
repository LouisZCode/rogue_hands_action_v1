class_name SpawnManager
extends Node

## Spawn Manager - High-Level Enemy Spawning Control
## Integrates with GameManager and controls multiple EnemySpawners
## Handles game-wide spawn logic and difficulty scaling

# Configuration
@export_group("Spawn Control")
@export var auto_spawn_enabled: bool = true
@export var difficulty_scaling: bool = true
@export var max_total_enemies: int = 3

# Difficulty progression
@export_group("Difficulty Scaling")
@export var base_spawn_rate: float = 5.0
@export var difficulty_multiplier: float = 0.1
@export var max_difficulty_level: int = 10

# Enemy type progression
@export_group("Enemy Type Progression")
@export var enable_advanced_enemies_after: int = 5  # enemies killed
@export var boss_spawn_interval: int = 10  # every X enemies killed

# Internal state
var spawners: Array[EnemySpawner] = []
var total_enemies_spawned: int = 0
var total_enemies_killed: int = 0
var current_difficulty_level: int = 1
var game_manager: GameManager

# Signals
signal enemy_spawned(enemy: Enemy)
signal difficulty_increased(new_level: int)
signal boss_spawned(enemy: Enemy)

func _ready():
	# Find GameManager
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		print("WARNING: SpawnManager could not find GameManager")
	
	# Find all EnemySpawners in the scene
	find_spawners()
	
	# Connect to spawner signals
	setup_spawner_connections()
	
	print("SpawnManager initialized with ", spawners.size(), " spawners")

func find_spawners():
	"""Find all EnemySpawner nodes in the scene"""
	spawners.clear()
	var all_spawners = get_tree().get_nodes_in_group("enemy_spawners")
	
	for spawner in all_spawners:
		if spawner is EnemySpawner:
			spawners.append(spawner)
	
	# If no spawners found, look for them as children
	if spawners.is_empty():
		for child in get_children():
			if child is EnemySpawner:
				spawners.append(child)

func setup_spawner_connections():
	"""Connect to all spawner signals"""
	for spawner in spawners:
		if not spawner.enemy_spawned.is_connected(_on_enemy_spawned):
			spawner.enemy_spawned.connect(_on_enemy_spawned)

func _on_enemy_spawned(enemy: Enemy):
	"""Handle enemy spawned by any spawner"""
	total_enemies_spawned += 1
	
	# Connect to enemy death for tracking
	if not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died)
	
	# Update difficulty if needed
	if difficulty_scaling:
		update_difficulty()
	
	enemy_spawned.emit(enemy)
	print("Total enemies spawned: ", total_enemies_spawned)

func _on_enemy_died():
	"""Handle enemy death for difficulty progression"""
	total_enemies_killed += 1
	
	# Check for boss spawn
	if total_enemies_killed % boss_spawn_interval == 0:
		spawn_boss()
	
	# Update enemy type availability
	if total_enemies_killed == enable_advanced_enemies_after:
		enable_advanced_enemy_types()
	
	print("Total enemies killed: ", total_enemies_killed)

func update_difficulty():
	"""Update difficulty based on enemies spawned"""
	var new_level = min(1 + (total_enemies_spawned / 3), max_difficulty_level)
	
	if new_level > current_difficulty_level:
		current_difficulty_level = new_level
		apply_difficulty_scaling()
		difficulty_increased.emit(current_difficulty_level)
		print("Difficulty increased to level ", current_difficulty_level)

func apply_difficulty_scaling():
	"""Apply difficulty scaling to all spawners"""
	var spawn_rate_multiplier = 1.0 - (current_difficulty_level * difficulty_multiplier)
	spawn_rate_multiplier = max(spawn_rate_multiplier, 0.3)  # Minimum 30% of base rate
	
	for spawner in spawners:
		spawner.spawn_cooldown = base_spawn_rate * spawn_rate_multiplier
		
		# Increase max enemies at higher difficulties
		if current_difficulty_level >= 3:
			spawner.max_enemies = 2
		if current_difficulty_level >= 6:
			spawner.max_enemies = 3

func enable_advanced_enemy_types():
	"""Enable more dangerous enemy types"""
	var advanced_weights = {
		"base": 20.0,
		"aggressive": 30.0,
		"defensive": 25.0,
		"tactical": 20.0,
		"berserker": 5.0
	}
	
	for spawner in spawners:
		spawner.set_enemy_weights(advanced_weights)
	
	print("Advanced enemy types enabled")

func spawn_boss():
	"""Spawn a boss enemy"""
	if spawners.is_empty():
		return
	
	# Use first spawner for boss
	var spawner = spawners[0]
	var boss = spawner.force_spawn_enemy("berserker")  # Berserker as mini-boss
	
	if boss:
		boss_spawned.emit(boss)
		print("Boss spawned!")

# Public interface

func start_spawning():
	"""Enable spawning on all spawners"""
	auto_spawn_enabled = true
	for spawner in spawners:
		spawner.spawn_enabled = true
	print("Spawning started")

func stop_spawning():
	"""Disable spawning on all spawners"""
	auto_spawn_enabled = false
	for spawner in spawners:
		spawner.spawn_enabled = false
	print("Spawning stopped")

func clear_all_enemies():
	"""Clear all enemies from all spawners"""
	for spawner in spawners:
		spawner.clear_all_enemies()
	print("All enemies cleared")

func force_spawn_wave():
	"""Force spawn a wave on all spawners"""
	for spawner in spawners:
		spawner.set_spawn_pattern(EnemySpawner.SpawnPattern.WAVE)
		spawner.force_spawn_enemy()

func set_global_enemy_weights(weights: Dictionary):
	"""Set enemy type weights for all spawners"""
	for spawner in spawners:
		spawner.set_enemy_weights(weights)

func get_total_active_enemies() -> int:
	"""Get total number of active enemies across all spawners"""
	var total = 0
	for spawner in spawners:
		total += spawner.get_enemy_count()
	return total

func get_spawn_stats() -> Dictionary:
	"""Get comprehensive spawn statistics"""
	return {
		"total_spawned": total_enemies_spawned,
		"total_killed": total_enemies_killed,
		"difficulty_level": current_difficulty_level,
		"active_enemies": get_total_active_enemies(),
		"spawners_count": spawners.size(),
		"auto_spawn_enabled": auto_spawn_enabled
	}

# Debug and testing methods

func force_difficulty_level(level: int):
	"""Force set difficulty level for testing"""
	current_difficulty_level = clamp(level, 1, max_difficulty_level)
	apply_difficulty_scaling()
	print("Forced difficulty to level ", current_difficulty_level)

func spawn_test_enemies():
	"""Spawn one of each enemy type for testing"""
	if spawners.is_empty():
		print("No spawners available for testing")
		return
	
	var spawner = spawners[0]
	var enemy_types = EnemyFactory.get_available_enemy_types()
	
	for enemy_type in enemy_types:
		spawner.force_spawn_enemy(enemy_type)
		await get_tree().create_timer(0.5).timeout  # Small delay between spawns
	
	print("Spawned test enemies: ", enemy_types)

func reset_spawn_stats():
	"""Reset all spawn statistics"""
	total_enemies_spawned = 0
	total_enemies_killed = 0
	current_difficulty_level = 1
	
	# Reset spawner settings
	for spawner in spawners:
		spawner.spawn_cooldown = base_spawn_rate
		spawner.max_enemies = 1
	
	print("Spawn statistics reset")