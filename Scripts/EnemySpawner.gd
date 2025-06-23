class_name EnemySpawner
extends Node2D

## Enemy Spawner System
## Handles spawning enemies with configurable patterns and types
## Integrates with EnemyFactory for proper resource management

# Spawn configuration
@export_group("Spawn Settings")
@export var spawn_enabled: bool = true
@export var max_enemies: int = 1
@export var spawn_cooldown: float = 3.0
@export var spawn_radius: float = 100.0  # Distance from spawner center

# Spawn boundaries (relative to spawner position)
@export_group("Spawn Boundaries")
@export var use_spawn_boundaries: bool = true
@export var boundary_min: Vector2 = Vector2(-300, -200)
@export var boundary_max: Vector2 = Vector2(300, 200)

# Enemy type selection
@export_group("Enemy Types")
@export var enemy_type_weights: Dictionary = {
	"base": 30.0,
	"aggressive": 20.0,
	"defensive": 20.0,
	"tactical": 15.0,
	"berserker": 5.0,
	"fast": 7.0,
	"tank": 3.0
}

# Spawn pattern configuration
@export_group("Spawn Patterns")
enum SpawnPattern { SINGLE, WAVE, CONTINUOUS, RANDOM }
@export var spawn_pattern: SpawnPattern = SpawnPattern.SINGLE
@export var wave_size: int = 3
@export var wave_delay: float = 8.0

# Internal state
var active_enemies: Array[Enemy] = []
var spawn_timer: float = 0.0
var wave_timer: float = 0.0
var enemies_spawned_in_wave: int = 0

# Signals
signal enemy_spawned(enemy: Enemy)
signal wave_completed()
signal spawn_limit_reached()

func _ready():
	# Preload all enemy resources for better performance
	EnemyFactory.preload_all_enemy_resources()
	
	# Set initial spawn timer
	spawn_timer = spawn_cooldown
	wave_timer = wave_delay
	
	print("EnemySpawner initialized - Pattern: ", SpawnPattern.keys()[spawn_pattern], " Max enemies: ", max_enemies)

func _process(delta):
	if not spawn_enabled:
		return
	
	# Update timers
	spawn_timer -= delta
	wave_timer -= delta
	
	# Clean up dead enemies from active list
	clean_up_dead_enemies()
	
	# Handle spawn patterns
	match spawn_pattern:
		SpawnPattern.SINGLE:
			handle_single_spawn()
		SpawnPattern.WAVE:
			handle_wave_spawn()
		SpawnPattern.CONTINUOUS:
			handle_continuous_spawn()
		SpawnPattern.RANDOM:
			handle_random_spawn()

func handle_single_spawn():
	"""Spawn one enemy when there are none active"""
	if active_enemies.is_empty() and spawn_timer <= 0:
		spawn_enemy()
		spawn_timer = spawn_cooldown

func handle_wave_spawn():
	"""Spawn enemies in waves"""
	if wave_timer <= 0 and active_enemies.is_empty():
		# Start new wave
		enemies_spawned_in_wave = 0
		for i in range(wave_size):
			if spawn_enemy():
				enemies_spawned_in_wave += 1
		
		wave_timer = wave_delay
		wave_completed.emit()
		print("Wave spawned: ", enemies_spawned_in_wave, " enemies")

func handle_continuous_spawn():
	"""Continuously spawn enemies up to max limit"""
	if active_enemies.size() < max_enemies and spawn_timer <= 0:
		spawn_enemy()
		spawn_timer = spawn_cooldown

func handle_random_spawn():
	"""Randomly spawn enemies with varying timing"""
	var random_cooldown = spawn_cooldown * randf_range(0.5, 1.5)
	if active_enemies.size() < max_enemies and spawn_timer <= 0:
		if randf() < 0.7:  # 70% chance to spawn
			spawn_enemy()
		spawn_timer = random_cooldown

func spawn_enemy() -> bool:
	"""Spawn a single enemy and return success status"""
	if not spawn_enabled:
		return false
	
	if active_enemies.size() >= max_enemies:
		spawn_limit_reached.emit()
		return false
	
	# Get spawn position
	var spawn_pos = get_spawn_position()
	if spawn_pos == Vector2.INF:  # Invalid position
		return false
	
	# Create enemy using factory
	var enemy = EnemyFactory.create_random_enemy(spawn_pos, enemy_type_weights)
	if not enemy:
		print("ERROR: Failed to create enemy")
		return false
	
	# Add to scene tree
	get_tree().current_scene.add_child(enemy)
	
	# Track the enemy
	active_enemies.append(enemy)
	
	# Connect to enemy death signal for cleanup
	if not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	
	enemy_spawned.emit(enemy)
	print("Spawned enemy: ", enemy.enemy_data.enemy_name, " at ", spawn_pos)
	return true

func spawn_enemy_by_type(enemy_type: String) -> bool:
	"""Spawn a specific enemy type"""
	if not spawn_enabled or active_enemies.size() >= max_enemies:
		return false
	
	var spawn_pos = get_spawn_position()
	if spawn_pos == Vector2.INF:
		return false
	
	var enemy = EnemyFactory.create_enemy_by_type(enemy_type, spawn_pos)
	if not enemy:
		return false
	
	get_tree().current_scene.add_child(enemy)
	active_enemies.append(enemy)
	
	if not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died.bind(enemy))
	
	enemy_spawned.emit(enemy)
	return true

func get_spawn_position() -> Vector2:
	"""Get a valid spawn position within boundaries"""
	var attempts = 0
	var max_attempts = 10
	
	while attempts < max_attempts:
		var angle = randf() * 2 * PI
		var distance = randf() * spawn_radius
		var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Check boundaries
		if use_spawn_boundaries:
			var local_pos = spawn_pos - global_position
			if local_pos.x < boundary_min.x or local_pos.x > boundary_max.x:
				attempts += 1
				continue
			if local_pos.y < boundary_min.y or local_pos.y > boundary_max.y:
				attempts += 1
				continue
		
		# Check for collision with existing enemies (minimum distance)
		var too_close = false
		var min_distance = 50.0
		for enemy in active_enemies:
			if enemy and enemy.global_position.distance_to(spawn_pos) < min_distance:
				too_close = true
				break
		
		if not too_close:
			return spawn_pos
		
		attempts += 1
	
	print("WARNING: Could not find valid spawn position after ", max_attempts, " attempts")
	return Vector2.INF

func _on_enemy_died(enemy: Enemy):
	"""Handle enemy death cleanup"""
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		print("Enemy died, ", active_enemies.size(), " enemies remaining")

func clean_up_dead_enemies():
	"""Remove dead/invalid enemies from tracking"""
	var valid_enemies: Array[Enemy] = []
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy):
			valid_enemies.append(enemy)
	active_enemies = valid_enemies

# Public interface methods

func set_spawn_pattern(pattern: SpawnPattern):
	"""Change spawn pattern at runtime"""
	spawn_pattern = pattern
	print("Spawn pattern changed to: ", SpawnPattern.keys()[pattern])

func set_enemy_weights(weights: Dictionary):
	"""Update enemy type probability weights"""
	enemy_type_weights = weights
	print("Updated enemy type weights: ", weights)

func force_spawn_enemy(enemy_type: String = "") -> bool:
	"""Force spawn an enemy ignoring cooldowns"""
	var old_timer = spawn_timer
	spawn_timer = 0.0
	
	var success = false
	if enemy_type.is_empty():
		success = spawn_enemy()
	else:
		success = spawn_enemy_by_type(enemy_type)
	
	spawn_timer = old_timer
	return success

func clear_all_enemies():
	"""Remove all active enemies"""
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	print("Cleared all active enemies")

func get_enemy_count() -> int:
	"""Get current number of active enemies"""
	clean_up_dead_enemies()
	return active_enemies.size()

func get_spawn_stats() -> Dictionary:
	"""Get spawner statistics"""
	return {
		"active_enemies": get_enemy_count(),
		"max_enemies": max_enemies,
		"spawn_pattern": SpawnPattern.keys()[spawn_pattern],
		"spawn_cooldown": spawn_cooldown,
		"spawn_enabled": spawn_enabled
	}

# Debug visualization
func _draw():
	if Engine.is_editor_hint():
		return
	
	# Draw spawn boundaries
	if use_spawn_boundaries:
		var rect = Rect2(boundary_min, boundary_max - boundary_min)
		draw_rect(rect, Color.YELLOW, false, 2.0)
	
	# Draw spawn radius
	draw_arc(Vector2.ZERO, spawn_radius, 0, 2 * PI, 32, Color.CYAN, 1.0)