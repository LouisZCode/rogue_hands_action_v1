extends CharacterBody2D
class_name Player

# Movement variables
@export var speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.3

# Combat variables
enum Stance { NEUTRAL, ROCK, PAPER, SCISSORS }
var current_stance: Stance = Stance.NEUTRAL
var max_health: int = 100
var current_health: int = 100

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

# Track which enemies have been hit during current dash
var enemies_hit_this_dash: Array[Node] = []

# References
@onready var sprite: ColorRect = $Sprite
@onready var stance_label: Label = $StanceLabel
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

func _ready():
	update_stance_visual()
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	
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
	
	# Check for attack hits during dash
	if is_dashing:
		attack_during_dash()

func handle_movement(delta):
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
	# Don't handle input during dash
	if is_dashing:
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
	sprite.color = stance_colors[current_stance]
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
			body.take_damage_from_player(current_stance, global_position)
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

func _on_attack_area_body_entered(body):
	# This is called when something enters attack range
	pass
