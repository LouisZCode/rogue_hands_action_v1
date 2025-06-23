class_name EnemyFactory
extends RefCounted

## Enemy Factory - Proper Resource Loading Pattern
## Creates enemy instances with correct resource assignment before scene tree addition
## Follows Godot 4.4 best practices for resource management

# Preload the enemy scene as PackedScene
static var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")

# Cache for loaded enemy resources to improve performance
static var resource_cache: Dictionary = {}

## Create an enemy instance with specified resource data
static func create_enemy(enemy_data: EnemyData, spawn_position: Vector2 = Vector2.ZERO) -> Enemy:
	if not enemy_data:
		print("ERROR: Cannot create enemy - no EnemyData provided")
		return null
	
	# Validate enemy data
	if not enemy_data.validate_data():
		print("WARNING: Invalid enemy data detected for ", enemy_data.enemy_name)
	
	# Create instance from PackedScene
	var enemy_instance = enemy_scene.instantiate() as Enemy
	if not enemy_instance:
		print("ERROR: Failed to instantiate enemy scene")
		return null
	
	# Set position before adding to scene tree
	enemy_instance.global_position = spawn_position
	
	# Apply enemy data BEFORE adding to scene tree (critical for proper loading)
	enemy_instance.set_enemy_data(enemy_data)
	
	print("Created enemy: ", enemy_data.enemy_name, " at position ", spawn_position)
	return enemy_instance

## Load enemy resource from file path with caching
static func load_enemy_resource(resource_path: String) -> EnemyData:
	# Check cache first
	if resource_cache.has(resource_path):
		return resource_cache[resource_path]
	
	# Load resource
	var resource = load(resource_path) as EnemyData
	if not resource:
		print("ERROR: Failed to load enemy resource from ", resource_path)
		return null
	
	# Cache for future use
	resource_cache[resource_path] = resource
	print("Loaded and cached enemy resource: ", resource.enemy_name)
	return resource

## Preload all enemy resources for better performance
static func preload_all_enemy_resources():
	print("Preloading all enemy resources...")
	
	var resource_paths = [
		"res://resources/BaseEnemy.tres",
		"res://resources/AggressiveEnemy.tres", 
		"res://resources/DefensiveEnemy.tres",
		"res://resources/TacticalEnemy.tres",
		"res://resources/BerserkerEnemy.tres",
		"res://resources/FastEnemy.tres",
		"res://resources/TankEnemy.tres"
	]
	
	for path in resource_paths:
		load_enemy_resource(path)
	
	print("Preloaded ", resource_cache.size(), " enemy resources")

## Create enemy by resource file path
static func create_enemy_from_path(resource_path: String, spawn_position: Vector2 = Vector2.ZERO) -> Enemy:
	var enemy_data = load_enemy_resource(resource_path)
	if not enemy_data:
		return null
	
	return create_enemy(enemy_data, spawn_position)

## Create enemy by archetype name (easier interface)
static func create_enemy_by_type(enemy_type: String, spawn_position: Vector2 = Vector2.ZERO) -> Enemy:
	var resource_path = get_resource_path_by_type(enemy_type)
	if resource_path.is_empty():
		print("ERROR: Unknown enemy type: ", enemy_type)
		return null
	
	return create_enemy_from_path(resource_path, spawn_position)

## Get resource path by enemy type name
static func get_resource_path_by_type(enemy_type: String) -> String:
	var type_map = {
		"base": "res://resources/BaseEnemy.tres",
		"aggressive": "res://resources/AggressiveEnemy.tres",
		"defensive": "res://resources/DefensiveEnemy.tres", 
		"tactical": "res://resources/TacticalEnemy.tres",
		"berserker": "res://resources/BerserkerEnemy.tres",
		"fast": "res://resources/FastEnemy.tres",
		"tank": "res://resources/TankEnemy.tres"
	}
	
	return type_map.get(enemy_type.to_lower(), "")

## Get all available enemy types
static func get_available_enemy_types() -> Array[String]:
	return ["base", "aggressive", "defensive", "tactical", "berserker", "fast", "tank"]

## Get random enemy type with optional weighting
static func get_random_enemy_type(weights: Dictionary = {}) -> String:
	var types = get_available_enemy_types()
	
	if weights.is_empty():
		# Equal probability for all types
		return types[randi() % types.size()]
	
	# Weighted selection
	var total_weight = 0.0
	for type in types:
		total_weight += weights.get(type, 1.0)
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for type in types:
		current_weight += weights.get(type, 1.0)
		if random_value <= current_weight:
			return type
	
	# Fallback
	return types[0]

## Create random enemy with optional type weighting
static func create_random_enemy(spawn_position: Vector2 = Vector2.ZERO, weights: Dictionary = {}) -> Enemy:
	var enemy_type = get_random_enemy_type(weights)
	return create_enemy_by_type(enemy_type, spawn_position)

## Clear resource cache (useful for memory management)
static func clear_resource_cache():
	resource_cache.clear()
	print("Cleared enemy resource cache")

## Get cache statistics
static func get_cache_stats() -> Dictionary:
	return {
		"cached_resources": resource_cache.size(),
		"cache_keys": resource_cache.keys()
	}