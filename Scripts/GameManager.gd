extends Node
class_name GameManager

# References
@onready var player_health_bar: ProgressBar = $"../UILayer/HealthUI/PlayerHealth"
@onready var stance_indicator: Label = $"../UILayer/HealthUI/StanceIndicator"
@onready var attack_cooldown_bar: ProgressBar = $"../UILayer/HealthUI/AttackCooldownBar"
@onready var cooldown_label: Label = $"../UILayer/HealthUI/CooldownLabel"
@onready var defense_point_1: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint1"
@onready var defense_point_2: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint2"
@onready var defense_point_3: Label = $"../UILayer/HealthUI/PlayerDefensePoints/DefensePoint3"
@onready var player: Player = $"../GameLayer/Player"
@onready var enemy: Enemy = $"../GameLayer/Enemy"

# Game state
var score: int = 0

func _ready():
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
	update_player_health_ui(player.current_health if player else 5)
	update_stance_ui(player.current_stance if player else Player.Stance.ROCK)
	update_attack_cooldown_ui(0.0, 1.0)  # Initialize cooldown bar
	update_player_defense_points_ui(3, 3)  # Initialize defense points

func _on_player_health_changed(new_health: int):
	update_player_health_ui(new_health)

func _on_player_stance_changed(new_stance: Player.Stance):
	update_stance_ui(new_stance)

func _on_player_attack(attacker_stance: Player.Stance, attack_position: Vector2):
	print("Player attacks with: ", Player.Stance.keys()[attacker_stance])

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
	# For now just print, enemy defense points visual will be added next
	print("Enemy defense points: ", current_defense, "/", max_defense)

func update_player_health_ui(health: int):
	if player_health_bar:
		var health_percent = float(health) / 5.0 * 100.0
		player_health_bar.value = health_percent
		
		# Change health bar color
		if health_percent > 66:
			player_health_bar.modulate = Color.GREEN
		elif health_percent > 33:
			player_health_bar.modulate = Color.YELLOW
		else:
			player_health_bar.modulate = Color.RED

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
	if attack_cooldown_bar and cooldown_label:
		# Update progress bar (inverted - full bar means ready, empty means cooling down)
		var progress = 1.0 - (current_cooldown / max_cooldown)
		attack_cooldown_bar.value = progress
		
		# Update label and color
		if current_cooldown <= 0:
			cooldown_label.text = "Attack Ready"
			attack_cooldown_bar.modulate = Color.GREEN
			# When cooldown completes and player is not in a stance, show neutral indicator
			if player and player.current_stance != Player.Stance.NEUTRAL:
				# Add visual indication that neutral stance is available
				cooldown_label.text = "Attack Ready - Return to 👤 Neutral"
		else:
			cooldown_label.text = "Cooldown: %.1fs" % current_cooldown
			attack_cooldown_bar.modulate = Color.RED

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

func spawn_new_enemy():
	# Create new enemy at random position
	var enemy_scene = preload("res://scenes/Enemy.tscn")
	var new_enemy = enemy_scene.instantiate()
	
	# Random spawn position around the edges
	var spawn_positions = [
		Vector2(-300, -200), Vector2(300, 200),
		Vector2(-300, 200), Vector2(300, -200)
	]
	new_enemy.global_position = spawn_positions[randi() % spawn_positions.size()]
	
	# Add to game layer
	$"../GameLayer".add_child(new_enemy)
	
	# Connect signals
	new_enemy.enemy_died.connect(_on_enemy_died)
	new_enemy.enemy_attack.connect(_on_enemy_attack)
	new_enemy.enemy_defense_points_changed.connect(_on_enemy_defense_points_changed)
	
	# Update enemy reference
	enemy = new_enemy

func game_over():
	print("Game Over! Final Score: ", score)
	# Handle game over (show menu, restart, etc.)
	get_tree().reload_current_scene()
