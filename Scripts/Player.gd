extends CharacterBody2D
class_name Player

# Movement variables
@export var speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.3

# Combat variables
enum Stance { NEUTRAL, ROCK, PAPER, SCISSORS }
var current_stance: Stance = Stance.NEUTRAL
var max_health: int = 5
var current_health: int = 5

# Defense point system
var max_defense_points: int = 3
var current_defense_points: int = 3

# Dash variables
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0

# Attack cooldown - increased to 1 second for balance
@export var attack_cooldown: float = 1.0
var attack_cooldown_timer: float = 0.0

# Immunity frames to prevent multiple hits
@export var immunity_duration: float = 0.5
var immunity_timer: float = 0.0
var is_immune: bool = false

# Stun system
@export var stun_duration: float = 3.0
var stun_timer: float = 0.0
var is_stunned: bool = false

# Track which enemies have been hit during current dash
var enemies_hit_this_dash: Array[Node] = []

# References
@onready var sprite: Sprite2D = $Sprite
@onready var stance_label: Label = $StanceLabel
@onready var stun_indicator: Label = $StunIndicator
@onready var attack_area: Area2D = $AttackArea

# Stance colors and symbols
var stance_colors = {
	Stance.NEUTRAL: Color.LIGHT_BLUE,
	Stance.ROCK: Color.GRAY,
	Stance.PAPER: Color.WHITE, 
	Stance.SCISSORS: Color.YELLOW
}

var stance_symbols = {
	Stance.NEUTRAL: "👤",
	Stance.ROCK: "✊",
	Stance.PAPER: "✋",
	Stance.SCISSORS: "✌️"
}

signal health_changed(new_health: int)
signal stance_changed(new_stance: Stance)
signal player_attack(attacker_stance: Stance, attack_position: Vector2)
signal attack_cooldown_changed(current_cooldown: float, max_cooldown: float)
signal defense_points_changed(current_defense: int, max_defense: int)

func _ready():
	update_stance_visual()
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	# Emit initial defense points
	defense_points_changed.emit(current_defense_points, max_defense_points)
	
func _physics_process(delta):
	handle_movement(delta)
	handle_input()
	
	# Update attack cooldown - only recover when in neutral stance
	if attack_cooldown_timer > 0 and current_stance == Stance.NEUTRAL:
		attack_cooldown_timer -= delta
		attack_cooldown_changed.emit(attack_cooldown_timer, attack_cooldown)
	
	# Update immunity frames
	if immunity_timer > 0:
		immunity_timer -= delta
		if immunity_timer <= 0:
			is_immune = false
			# Reset visual feedback when immunity ends
			sprite.modulate = Color.WHITE
	
	# Update stun timer
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			# Reset visual feedback when stun ends
			sprite.modulate = Color.WHITE
			if stun_indicator:
				stun_indicator.visible = false
	
	# Check for attack hits during dash
	if is_dashing:
		attack_during_dash()

func handle_movement(delta):
	# No movement allowed when stunned
	if is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Handle dash movement
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = Vector2.ZERO
			# Auto-return to neutral stance after dash
			change_stance(Stance.NEUTRAL)
		else:
			velocity = dash_direction * dash_speed
	else:
		# Only allow normal movement in neutral stance
		if current_stance == Stance.NEUTRAL:
			# Get input direction
			var input_dir = Vector2.ZERO
			
			if Input.is_action_pressed("move_up"):
				input_dir.y -= 1
			if Input.is_action_pressed("move_down"):
				input_dir.y += 1
			if Input.is_action_pressed("move_left"):
				input_dir.x -= 1
			if Input.is_action_pressed("move_right"):
				input_dir.x += 1
			
			# Normalize diagonal movement
			if input_dir.length() > 0:
				input_dir = input_dir.normalized()
				velocity = input_dir * speed
			else:
				velocity = Vector2.ZERO
		else:
			# Stop movement when in stance
			velocity = Vector2.ZERO
	
	move_and_slide()

func handle_input():
	# Don't handle input during dash or stun
	if is_dashing or is_stunned:
		return
		
	# Stance selection - hold keys to maintain stance
	var new_stance = Stance.NEUTRAL
	
	if Input.is_action_pressed("gesture_rock"):
		new_stance = Stance.ROCK
	elif Input.is_action_pressed("gesture_paper"):
		new_stance = Stance.PAPER
	elif Input.is_action_pressed("gesture_scissors"):  
		new_stance = Stance.SCISSORS
	
	# Only change stance if it's different
	if new_stance != current_stance:
		change_stance(new_stance)
	
	# Directional dash attacks - only allow if not in neutral stance and not on cooldown
	if Input.is_action_just_pressed("attack") and current_stance != Stance.NEUTRAL and attack_cooldown_timer <= 0:
		var attack_direction = Vector2.ZERO
		
		# Check for directional input
		if Input.is_action_pressed("move_up"):
			attack_direction.y -= 1
		if Input.is_action_pressed("move_down"):
			attack_direction.y += 1
		if Input.is_action_pressed("move_left"):
			attack_direction.x -= 1
		if Input.is_action_pressed("move_right"):
			attack_direction.x += 1
		
		# If no direction pressed, don't attack
		if attack_direction.length() > 0:
			attack_direction = attack_direction.normalized()
			perform_dash_attack(attack_direction)

func change_stance(new_stance: Stance):
	if current_stance != new_stance:
		current_stance = new_stance
		update_stance_visual()
		stance_changed.emit(current_stance)

func update_stance_visual():
	# Update sprite texture based on stance
	match current_stance:
		Stance.NEUTRAL:
			sprite.texture = preload("res://assets/test_sprites/idle_player.png")
		Stance.ROCK:
			sprite.texture = preload("res://assets/test_sprites/rock_player.png")
		Stance.PAPER:
			sprite.texture = preload("res://assets/test_sprites/paper_player.png")
		Stance.SCISSORS:
			sprite.texture = preload("res://assets/test_sprites/scissor_player.png")
	
	stance_label.text = stance_symbols[current_stance]

func perform_dash_attack(direction: Vector2):
	# Start the dash
	is_dashing = true
	dash_direction = direction
	dash_timer = dash_duration
	
	# Start attack cooldown
	attack_cooldown_timer = attack_cooldown
	
	# Clear the list of enemies hit this dash
	enemies_hit_this_dash.clear()
	
	# Visual feedback for dash attack
	var dash_color = stance_colors[current_stance].lerp(Color.WHITE, 0.5)
	sprite.modulate = dash_color
	
	# Reset color after dash and auto-return to neutral
	var tween = create_tween()
	tween.tween_interval(dash_duration)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_callback(func(): 
		current_stance = Stance.NEUTRAL
		update_stance_visual()
		stance_changed.emit(current_stance)
	)
	
	# Emit signal with current stance and position
	player_attack.emit(current_stance, global_position)

func attack_during_dash():
	# Check for enemies in attack range during dash
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage_from_player") and not body in enemies_hit_this_dash:
			# Detect combat scenario: mutual attack or attack vs defense
			var is_mutual_attack = detect_mutual_attack(body)
			body.take_damage_from_player(current_stance, global_position, is_mutual_attack)
			# Add enemy to the list of already hit enemies
			enemies_hit_this_dash.append(body)

func take_damage(amount: int):
	# Don't take damage if immune
	if is_immune:
		return
		
	# Players in neutral stance take reduced damage (25% of original damage)
	var final_damage = amount
	if current_stance == Stance.NEUTRAL:
		final_damage = max(1, amount / 4)  # 25% damage, minimum 1
		
	current_health = max(0, current_health - final_damage)
	health_changed.emit(current_health)
	
	# Create hit particle effect
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.particle_manager:
		game_manager.particle_manager.create_hit_effect(global_position)
	
	# Start immunity frames
	is_immune = true
	immunity_timer = immunity_duration
	
	# Visual feedback for taking damage (different color for neutral stance)
	var tween = create_tween()
	if current_stance == Stance.NEUTRAL:
		# Blue flash for reduced damage in neutral stance
		tween.tween_property(sprite, "modulate", Color.CYAN, 0.1)
		tween.tween_property(sprite, "modulate", Color.LIGHT_BLUE, 0.1)
	else:
		# Red flash for normal damage
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.PINK, 0.1)
	
	# Add immunity frame visual feedback (flickering)
	tween.tween_callback(func(): add_immunity_visual_feedback())
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func consume_defense_point() -> bool:
	if current_defense_points > 0:
		current_defense_points -= 1
		defense_points_changed.emit(current_defense_points, max_defense_points)
		return true
	return false

func apply_stun():
	is_stunned = true
	stun_timer = stun_duration
	
	# Cancel any ongoing dash immediately
	if is_dashing:
		is_dashing = false
		dash_timer = 0.0
		velocity = Vector2.ZERO
	
	# Always change to neutral stance when stunned
	change_stance(Stance.NEUTRAL)
	
	# Visual feedback for stun
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.PURPLE, 0.2)
	# Show stun indicator
	if stun_indicator:
		stun_indicator.visible = true
	print("Player stunned for ", stun_duration, " seconds!")

func die():
	print("Player died!")
	# Handle player death (restart game, etc.)
	get_tree().reload_current_scene()

func add_immunity_visual_feedback():
	# Create flickering effect during immunity frames
	if is_immune:
		var flicker_tween = create_tween()
		flicker_tween.set_loops(int(immunity_duration * 10))  # Flicker 10 times per second
		flicker_tween.tween_property(sprite, "modulate:a", 0.3, 0.05)
		flicker_tween.tween_property(sprite, "modulate:a", 1.0, 0.05)

func is_currently_dashing() -> bool:
	return is_dashing

func detect_mutual_attack(enemy_body) -> bool:
	# Check if enemy is also dashing (mutual attack scenario)
	if enemy_body.has_method("is_currently_dashing"):
		return enemy_body.is_currently_dashing()
	return false

func _on_attack_area_body_entered(body):
	# This is called when something enters attack range
	pass
