extends Node
class_name GameManager

# References
@onready var stance_indicator: Label = $"../UILayer/HealthUI/StanceIndicator"
@onready var defense_point_1: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint1"
@onready var defense_point_2: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint2"
@onready var defense_point_3: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint3"
@onready var player_hearts_container: HBoxContainer = $"../UILayer/HealthUI/PlayerHearts"
@onready var player: Player = $"../GameLayer/Player"
@onready var enemy: Enemy = $"../GameLayer/Enemy"

# Heart management
var heart_labels: Array[Label] = []

# Particle manager reference
var particle_manager: ParticleManager

# Game state
var score: int = 0

func _ready():
	# Check if another GameManager already exists
	var existing_managers = get_tree().get_nodes_in_group("game_manager")
	if existing_managers.size() > 0:
		print("WARNING: Multiple GameManagers detected! Current count: ", existing_managers.size() + 1)
		for manager in existing_managers:
			print("  Existing manager: ", manager.name, " at ", manager.get_path())
	
	# Add to game_manager group for easy access
	add_to_group("game_manager")
	
	# Initialize particle manager only if we don't have one already
	if not particle_manager:
		particle_manager = ParticleManager.new()
		add_child(particle_manager)
		print("GameManager initialized with new ParticleManager")
	else:
		print("GameManager reusing existing ParticleManager")
	
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

func _input(event):
	# Debug input handling for testing the enemy system
	if event.is_action_pressed("ui_accept"):  # Enter key
		print("Testing enemy factory...")
		test_enemy_factory()
	elif event.is_action_pressed("ui_select"):  # Spacebar
		print("Testing random enemies...")
		test_random_enemies()
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		print("Clearing enemies...")
		clear_all_enemies()
	elif event.is_action_pressed("ui_home"):  # Home key
		get_factory_stats()
	
	# Initialize particle manager
	particle_manager = ParticleManager.new()
	add_child(particle_manager)
	
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

func _on_player_health_changed(new_health: int):
	update_hearts_display(new_health)

func _on_player_stance_changed(new_stance: Player.Stance):
	update_stance_ui(new_stance)
	# Removed stance change particles for cleaner gameplay

func _on_player_attack(attacker_stance: Player.Stance, attack_position: Vector2):
	print("Player attacks with: ", Player.Stance.keys()[attacker_stance])
	# Removed attack particles for cleaner gameplay

func _on_player_attack_cooldown_changed(current_cooldown: float, max_cooldown: float):
	update_attack_cooldown_ui(current_cooldown, max_cooldown)

func _on_enemy_died():
	score += 1
	print("Enemy defeated! Score: ", score)
	# Create death particle effect
	if particle_manager and enemy:
		particle_manager.create_death_effect(enemy.global_position)
	# Spawn new enemy after a delay
	var timer = create_tween()
	timer.tween_callback(spawn_new_enemy).set_delay(2.0)

func _on_enemy_attack(attacker_stance: Enemy.Stance, attack_position: Vector2):
	print("Enemy attacks with: ", Enemy.Stance.keys()[attacker_stance])
	# Removed attack particles for cleaner gameplay

func _on_player_defense_points_changed(current_defense: int, max_defense: int):
	update_player_defense_points_ui(current_defense, max_defense)

func _on_enemy_defense_points_changed(current_defense: int, max_defense: int):
	# For now just print, enemy defense points visual will be added next
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
	# Use new EnemyFactory system for proper resource loading
	var spawn_positions = [
		Vector2(-300, -200), Vector2(300, 200),
		Vector2(-300, 200), Vector2(300, -200)
	]
	var spawn_pos = spawn_positions[randi() % spawn_positions.size()]
	
	# Create enemy with random type using factory
	var new_enemy = EnemyFactory.create_random_enemy(spawn_pos)
	
	if new_enemy:
		# Add to game layer
		$"../GameLayer".add_child(new_enemy)
		
		# Connect signals
		new_enemy.enemy_died.connect(_on_enemy_died)
		new_enemy.enemy_attack.connect(_on_enemy_attack)
		new_enemy.enemy_defense_points_changed.connect(_on_enemy_defense_points_changed)
		
		print("Spawned new enemy using factory system: ", new_enemy.enemy_data.enemy_name)
	else:
		print("ERROR: Failed to spawn new enemy")
	
	# Update enemy reference
	enemy = new_enemy

# Debug and testing functions

func test_enemy_factory():
	"""Test the enemy factory by spawning all enemy types"""
	print("=== TESTING ENEMY FACTORY ===")
	
	# Clear existing enemies first
	clear_all_enemies()
	
	# Test spawning each enemy type
	var enemy_types = EnemyFactory.get_available_enemy_types()
	var spawn_positions = [
		Vector2(-200, -100), Vector2(0, -100), Vector2(200, -100),
		Vector2(-200, 100), Vector2(0, 100), Vector2(200, 100),
		Vector2(-100, 0)
	]
	
	for i in range(enemy_types.size()):
		var enemy_type = enemy_types[i]
		var spawn_pos = spawn_positions[i % spawn_positions.size()]
		
		var test_enemy = EnemyFactory.create_enemy_by_type(enemy_type, spawn_pos)
		if test_enemy:
			$"../GameLayer".add_child(test_enemy)
			test_enemy.enemy_died.connect(_on_enemy_died)
			test_enemy.enemy_attack.connect(_on_enemy_attack)
			test_enemy.enemy_defense_points_changed.connect(_on_enemy_defense_points_changed)
			print("Spawned test enemy: ", test_enemy.enemy_data.enemy_name, " at ", spawn_pos)
		else:
			print("ERROR: Failed to spawn ", enemy_type)
	
	print("Factory test complete - spawned ", enemy_types.size(), " different enemy types")

func test_random_enemies():
	"""Test random enemy spawning"""
	print("=== TESTING RANDOM ENEMY SPAWNING ===")
	
	clear_all_enemies()
	
	# Spawn 5 random enemies
	for i in range(5):
		var angle = (i * 72.0) * PI / 180.0  # 72 degrees apart in circle
		var radius = 150.0
		var spawn_pos = Vector2(cos(angle), sin(angle)) * radius
		
		var random_enemy = EnemyFactory.create_random_enemy(spawn_pos)
		if random_enemy:
			$"../GameLayer".add_child(random_enemy)
			random_enemy.enemy_died.connect(_on_enemy_died)
			random_enemy.enemy_attack.connect(_on_enemy_attack)
			random_enemy.enemy_defense_points_changed.connect(_on_enemy_defense_points_changed)
		
		# Small delay between spawns
		await get_tree().create_timer(0.3).timeout
	
	print("Random enemy test complete")

func clear_all_enemies():
	"""Remove all enemies except the original one"""
	var game_layer = $"../GameLayer"
	for child in game_layer.get_children():
		if child is Enemy and child != enemy:  # Keep original enemy
			child.queue_free()
	print("Cleared all test enemies")

func get_factory_stats():
	"""Print factory statistics"""
	var stats = EnemyFactory.get_cache_stats()
	print("=== FACTORY STATS ===")
	print("Cached resources: ", stats.cached_resources)
	print("Cache keys: ", stats.cache_keys)

func game_over():
	print("Game Over! Final Score: ", score)
	# Handle game over (show menu, restart, etc.)
	get_tree().reload_current_scene()
