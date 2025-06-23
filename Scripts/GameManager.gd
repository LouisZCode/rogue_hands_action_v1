extends Node
class_name GameManager

# References
@onready var stance_indicator: Label = $"../UILayer/HealthUI/StanceIndicator"
@onready var defense_point_1: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint1"
@onready var defense_point_2: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint2"
@onready var defense_point_3: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint3"
@onready var player_hearts_container: HBoxContainer = $"../UILayer/HealthUI/PlayerHearts"
@onready var player: Player = $"../GameLayer/Player"
var enemy: Enemy = null  # Will be spawned from resources

# Heart management
var heart_labels: Array[Label] = []

# Game state
var score: int = 0

# Enemy spawning system
var input_buffer: String = ""
var enemy_types_list: Array[String] = []

func _ready():
	# Check if another GameManager already exists
	var existing_managers = get_tree().get_nodes_in_group("game_manager")
	if existing_managers.size() > 0:
		print("WARNING: Multiple GameManagers detected! Current count: ", existing_managers.size() + 1)
		for manager in existing_managers:
			print("  Existing manager: ", manager.name, " at ", manager.get_path())
	
	# Add to game_manager group for easy access
	add_to_group("game_manager")
	
	# ParticleManager system disabled for cleaner gameplay
	print("GameManager initialized without ParticleManager (disabled for testing)")
	
	# Connect player signals
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.stance_changed.connect(_on_player_stance_changed)
		player.player_attack.connect(_on_player_attack)
		player.attack_cooldown_changed.connect(_on_player_attack_cooldown_changed)
		player.defense_points_changed.connect(_on_player_defense_points_changed)

	# Connect enemy signals  
	if enemy:
		enemy.enemy_died.connect(_on_enemy_died)
		enemy.enemy_attack.connect(_on_enemy_attack)
		enemy.enemy_defense_points_changed.connect(_on_enemy_defense_points_changed)

	# Initialize UI
	update_stance_ui(player.current_stance if player else Player.Stance.ROCK)
	update_attack_cooldown_ui(0.0, 1.0)  # Initialize cooldown bar
	update_player_defense_points_ui(3, 3)  # Initialize defense points
	# Initialize hearts based on player's max health
	initialize_hearts(player.max_health if player else 5)
	
	# Spawn first enemy from resource system
	spawn_enemy_by_resource("BasicEnemy")
	
	# Initialize enemy database manager
	var db_manager = EnemyDatabaseManager.new()
	add_child(db_manager)
	
	# Initialize enemy spawning system
	initialize_enemy_spawning_system()

func _on_player_health_changed(new_health: int):
	update_hearts_display(new_health)

func _on_player_stance_changed(new_stance: Player.Stance):
	update_stance_ui(new_stance)

func _on_player_attack(attacker_stance: Player.Stance, attack_position: Vector2):
	# print("Player attacks with: ", Player.Stance.keys()[attacker_stance])
	pass

func _on_player_attack_cooldown_changed(current_cooldown: float, max_cooldown: float):
	update_attack_cooldown_ui(current_cooldown, max_cooldown)

func _on_enemy_died():
	score += 1
	print("Enemy defeated! Score: ", score)
	# Spawn new enemy after a delay
	var timer = create_tween()
	timer.tween_callback(spawn_new_enemy).set_delay(2.0)

func _on_enemy_attack(attacker_stance: Enemy.Stance, attack_position: Vector2):
	print("Enemy attacks with: ", Enemy.Stance.keys()[attacker_stance])

func _on_player_defense_points_changed(current_defense: int, max_defense: int):
	update_player_defense_points_ui(current_defense, max_defense)

func _on_enemy_defense_points_changed(current_defense: int, max_defense: int):
	print("Enemy defense points: ", current_defense, "/", max_defense)


func update_stance_ui(stance: Player.Stance):
	if stance_indicator:
		match stance:
			Player.Stance.NEUTRAL:
				stance_indicator.text = "NEUTRAL 👤"
				stance_indicator.modulate = Color.LIGHT_BLUE
				# Add subtle pulsing effect for neutral stance to show it's defensive
				var tween = create_tween()
				tween.set_loops()
				tween.tween_property(stance_indicator, "modulate", Color.CYAN, 1.0)
				tween.tween_property(stance_indicator, "modulate", Color.LIGHT_BLUE, 1.0)
			Player.Stance.ROCK:
				stance_indicator.text = "ROCK ✊"
				stance_indicator.modulate = Color.GRAY
			Player.Stance.PAPER:
				stance_indicator.text = "PAPER ✋"  
				stance_indicator.modulate = Color.WHITE
			Player.Stance.SCISSORS:
				stance_indicator.text = "SCISSORS ✌️"
				stance_indicator.modulate = Color.YELLOW

func update_attack_cooldown_ui(current_cooldown: float, max_cooldown: float):
	if player and player.attack_cooldown_bar:
		# Update progress bar (inverted - full bar means ready, empty means cooling down)
		var progress = 1.0 - (current_cooldown / max_cooldown)
		player.attack_cooldown_bar.value = progress
		
		# Update color
		if current_cooldown <= 0:
			player.attack_cooldown_bar.modulate = Color.GREEN
		else:
			player.attack_cooldown_bar.modulate = Color.RED

func update_player_defense_points_ui(current_defense: int, max_defense: int):
	# Update defense point visual indicators
	var defense_points = [defense_point_1, defense_point_2, defense_point_3]
	
	for i in range(max_defense):
		if i < defense_points.size() and defense_points[i]:
			if i < current_defense:
				defense_points[i].text = "🛡️"  # Active defense point
				defense_points[i].modulate = Color.WHITE
			else:
				defense_points[i].text = "💔"  # Used defense point
				defense_points[i].modulate = Color.GRAY

func initialize_hearts(max_health: int):
	# Create heart labels dynamically based on max health
	for i in range(max_health):
		var heart_label = Label.new()
		heart_label.text = "❤️"
		heart_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		player_hearts_container.add_child(heart_label)
		heart_labels.append(heart_label)

func update_hearts_display(current_health: int):
	# Update heart display based on current health (show broken hearts for missing health)
	for i in range(heart_labels.size()):
		if heart_labels[i]:
			if i < current_health:
				heart_labels[i].text = "❤️"  # Full heart
				heart_labels[i].modulate = Color.WHITE
				heart_labels[i].visible = true
			else:
				heart_labels[i].text = "💔"  # Broken heart
				heart_labels[i].modulate = Color.GRAY
				heart_labels[i].visible = true

func spawn_new_enemy():
	# Spawn random enemy archetype after death for variety
	var spawn_positions = [
		Vector2(-300, -200), Vector2(300, 200),
		Vector2(-300, 200), Vector2(300, -200)
	]
	var spawn_pos = spawn_positions[randi() % spawn_positions.size()]
	
	# Spawn random enemy archetype
	var new_enemy = spawn_random_enemy_archetype(spawn_pos)
	if new_enemy:
		print("Spawned new random enemy at: ", spawn_pos)
	else:
		print("ERROR: Failed to spawn new enemy")

func spawn_enemy_by_resource(resource_name: String, spawn_position: Vector2 = Vector2.ZERO):
	"""Spawn an enemy from a .tres resource file"""
	var resource_path = "res://Resources/Enemies/" + resource_name + ".tres"
	var enemy_data = load(resource_path) as EnemyData
	
	if not enemy_data:
		print("ERROR: Failed to load enemy resource: ", resource_path)
		return null
	
	# Create enemy from scene
	var enemy_scene = preload("res://scenes/Enemy.tscn")
	var new_enemy = enemy_scene.instantiate() as Enemy
	
	if not new_enemy:
		print("ERROR: Failed to instantiate enemy scene")
		return null
	
	# Set position (use center of screen if no position specified)
	if spawn_position == Vector2.ZERO:
		spawn_position = Vector2(200, -150)  # Default enemy position
	new_enemy.global_position = spawn_position
	
	# Apply enemy data before adding to scene tree
	new_enemy.enemy_data = enemy_data
	
	# Add to game layer
	$"../GameLayer".add_child(new_enemy)
	
	# Connect signals
	new_enemy.enemy_died.connect(_on_enemy_died)
	new_enemy.enemy_attack.connect(_on_enemy_attack)
	new_enemy.enemy_defense_points_changed.connect(_on_enemy_defense_points_changed)
	
	# Update enemy reference
	enemy = new_enemy
	
	print("Spawned enemy: ", enemy_data.enemy_name, " from resource: ", resource_name)
	return new_enemy


func refresh_enemy_resources():
	"""Refresh available enemy types after CSV import"""
	print("🔄 Refreshing enemy resource cache...")
	# Update available enemy types for random spawning
	var updated_types = get_available_enemy_types()
	print("📋 Available enemy types: ", updated_types)

func get_available_enemy_types() -> Array[String]:
	"""Get list of all available enemy resource names"""
	var enemy_types: Array[String] = []
	var dir = DirAccess.open("res://Resources/Enemies/")
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				# Remove .tres extension to get resource name
				var resource_name = file_name.get_basename()
				enemy_types.append(resource_name)
			file_name = dir.get_next()
	
	return enemy_types

func spawn_random_enemy_archetype(spawn_position: Vector2 = Vector2.ZERO):
	"""Spawn a random enemy archetype for testing - now uses dynamic enemy list"""
	var enemy_types = get_available_enemy_types()
	
	if enemy_types.size() == 0:
		print("ERROR: No enemy resources found in res://Resources/Enemies/")
		return null
	
	var random_type = enemy_types[randi() % enemy_types.size()]
	return spawn_enemy_by_resource(random_type, spawn_position)

func game_over():
	print("Game Over! Final Score: ", score)
	# Handle game over (show menu, restart, etc.)
	get_tree().reload_current_scene()

# === ENEMY SPAWNING SYSTEM ===

func _input(event):
	# Handle number + enter enemy spawning
	if event is InputEventKey and event.pressed:
		handle_enemy_spawn_input(event)

func initialize_enemy_spawning_system():
	"""Initialize the enemy spawning system and show instructions"""
	enemy_types_list = get_available_enemy_types()
	
	print("\n" + "=".repeat(50))
	print("🎮 ENEMY SPAWNING SYSTEM READY")
	print("=".repeat(50))
	print("Type enemy number + [ENTER] to spawn:")
	print("")
	
	for i in range(enemy_types_list.size()):
		var enemy_name = enemy_types_list[i].replace("Enemy", "")
		print("  %d. %s" % [i + 1, enemy_name])
	
	print("")
	print("Example: Type '3' then [ENTER] to spawn enemy #3")
	print("Clear existing enemy before spawning new one")
	print("=".repeat(50) + "\n")

func handle_enemy_spawn_input(event: InputEventKey):
	"""Handle number and enter key inputs for enemy spawning"""
	var key_code = event.keycode
	
	# Handle number keys (0-9)
	if key_code >= KEY_0 and key_code <= KEY_9:
		var digit = str(key_code - KEY_0)
		input_buffer += digit
		print("Input: " + input_buffer)
	
	# Handle Enter key
	elif key_code == KEY_ENTER:
		if input_buffer.length() > 0:
			spawn_enemy_by_number(int(input_buffer))
			input_buffer = ""  # Clear buffer
		else:
			print("❌ Enter a number first, then press Enter")
	
	# Handle Backspace (optional - clear buffer)
	elif key_code == KEY_BACKSPACE:
		if input_buffer.length() > 0:
			input_buffer = input_buffer.substr(0, input_buffer.length() - 1)
			print("Input: " + input_buffer if input_buffer.length() > 0 else "Input cleared")

func spawn_enemy_by_number(enemy_number: int):
	"""Spawn an enemy by its number in the list"""
	if enemy_number < 1 or enemy_number > enemy_types_list.size():
		print("❌ Invalid enemy number! Valid range: 1-%d" % enemy_types_list.size())
		return
	
	# Remove existing enemy first
	clear_current_enemy()
	
	# Spawn the selected enemy
	var enemy_type = enemy_types_list[enemy_number - 1]
	var spawn_position = Vector2(200, -150)  # Default spawn position
	
	var new_enemy = spawn_enemy_by_resource(enemy_type, spawn_position)
	if new_enemy:
		var display_name = enemy_type.replace("Enemy", "")
		print("✅ Spawned Enemy #%d: %s" % [enemy_number, display_name])
	else:
		print("❌ Failed to spawn enemy #%d" % enemy_number)

func clear_current_enemy():
	"""Remove the current enemy from the scene"""
	if enemy and is_instance_valid(enemy):
		enemy.queue_free()
		enemy = null
