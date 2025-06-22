extends CharacterBody2D
class_name Player

# Movement variables
@export var speed: float = 200.0
@export var dash_speed: float = 600.0
@export var dash_duration: float = 0.3  # Half of enemy dash distance

# Movement interpolation
@export var acceleration: float = 800.0  # Units per second squared (4x speed for responsive feel)
@export var deceleration: float = 1000.0  # Units per second squared (5x speed for quick stops)
var current_speed: float = 0.0  # Current movement speed

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
var dash_preserved_scale: Vector2 = Vector2.ZERO  # Store scale before dash to prevent corruption

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

# Parry window system
@export var parry_window_duration: float = 0.5
var parry_window_timer: float = 0.0
var is_parry_window_active: bool = false

# Track which enemies have been hit during current dash
var enemies_hit_this_dash: Array[Node] = []

# Animation state management
var current_animation_state: String = "idle"
var movement_threshold: float = 10.0  # Minimum velocity to trigger walking animation

# Long idle system
var idle_timer: float = 0.0
var long_idle_delay: float = 5.0  # 5 seconds before long idle triggers
var is_in_long_idle: bool = false

var base_position: Vector2
var base_scale: Vector2 = Vector2(1.0, 1.0)

# Directional rotation
var current_rotation: float = 0.0
var rotation_tween: Tween
var stance_rotation_speed: float = 0.15  # Faster rotation for stance feedback

# Direction preservation system
var last_movement_direction: float = 0.0  # Preserve last walking direction
var entering_stance_direction: float = 0.0  # Direction when entering stance
var previous_stance: Stance = Stance.NEUTRAL  # Track stance changes

# References
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var eye_sprite: AnimatedSprite2D = $EyeSprite
@onready var stance_label: Label = $StanceLabel
@onready var stun_indicator: Label = $StunIndicator
@onready var attack_area: Area2D = $AttackArea
@onready var walking_audio: AudioStreamPlayer2D = $WalkingAudioPlayer
@onready var parry_circle: ParryCircle = $ParryCircle
@onready var defense_circles: DefenseCircles = $DefenseCircles
@onready var attack_cooldown_bar: ProgressBar = $AttackCooldownBar
@onready var dash_preview: DashPreview = $DashPreview

# Audio management
var audio_manager: AudioManager
var is_walking_audio_playing: bool = false

# Screen shake system
var shake_duration: float = 0.0
var shake_intensity: float = 0.0
var shake_timer: float = 0.0
var base_camera_position: Vector2
var scene_camera: Camera2D = null

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
	# Add to player group for easy access by enemies
	add_to_group("player")
	
	# Find the scene camera
	scene_camera = get_tree().get_first_node_in_group("scene_camera")
	if not scene_camera:
		# Fallback: search for Camera2D in scene root
		var scene_root = get_tree().current_scene
		scene_camera = scene_root.find_child("Camera2D", true, false)
	
	if scene_camera:
		base_camera_position = scene_camera.position
	
	update_stance_visual()
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	# Emit initial defense points
	defense_points_changed.emit(current_defense_points, max_defense_points)
	# Store base position for bobbing effect
	base_position = sprite.position
	# Initialize rotation tween
	rotation_tween = create_tween()
	rotation_tween.kill()  # Stop it initially
	# Initialize audio manager
	audio_manager = AudioManager.new()
	# Initialize dash preview
	if dash_preview:
		dash_preview.set_player_style()
	# Initialize parry circle as hidden
	if parry_circle:
		parry_circle.hide_parry_circle()
	# Initialize defense circles as hidden (only show in combat stances)
	if defense_circles:
		defense_circles.update_defense_points(current_defense_points)
		defense_circles.hide_defense_circles()
	# Initialize attack cooldown bar as hidden
	if attack_cooldown_bar:
		attack_cooldown_bar.visible = false
	
	# Connect animation finished signal for long idle
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Debug initial long idle values
	# print("DEBUG: Long idle system initialized - delay: ", long_idle_delay, " is_in_long_idle: ", is_in_long_idle)
	
func _physics_process(delta):
	handle_movement(delta)
	handle_input()
	update_dash_preview()
	update_animation_state(delta)
	update_screen_shake(delta)
	update_parry_window(delta)
	
	# Safety check for defense circles visibility
	if defense_circles:
		defense_circles.validate_visibility_state(Stance.keys()[current_stance])
	
	# Update attack cooldown - only recover when in neutral stance
	if attack_cooldown_timer > 0 and current_stance == Stance.NEUTRAL:
		attack_cooldown_timer -= delta
		attack_cooldown_changed.emit(attack_cooldown_timer, attack_cooldown)
	
	# Update attack cooldown bar visibility - only show while charging and in idle/walking states
	update_attack_cooldown_bar_visibility()
	
	# Update long idle timer
	update_long_idle_timer(delta)
	
	# Debug: Manual long idle trigger (press L key)
	# if Input.is_action_just_pressed("ui_select") or Input.is_key_pressed(KEY_L):
	#	print("DEBUG: Manual long idle trigger pressed!")
	#	if not is_in_long_idle:
	#		trigger_long_idle()
	#	else:
	#		exit_long_idle()
	#	pass
	
	# Sync eye sprite rotation continuously
	sync_eye_sprite_rotation()
	
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
		current_speed = 0.0  # Reset speed when stunned
		move_and_slide()
		return
	
	# Handle dash movement
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = Vector2.ZERO
			# Restore preserved scale when dash ends
			if dash_preserved_scale != Vector2.ZERO:
				sprite.scale = dash_preserved_scale
				dash_preserved_scale = Vector2.ZERO
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
				
				# Smooth acceleration toward target speed
				var target_speed = speed
				current_speed = move_toward(current_speed, target_speed, acceleration * delta)
				velocity = input_dir * current_speed
			else:
				# Smooth deceleration when no input
				current_speed = move_toward(current_speed, 0.0, deceleration * delta)
				
				# Preserve direction until fully stopped
				if velocity.length() > 0 and current_speed > 0:
					velocity = velocity.normalized() * current_speed
				else:
					velocity = Vector2.ZERO
		else:
			# Stop movement when in stance (with deceleration)
			current_speed = move_toward(current_speed, 0.0, deceleration * delta)
			if velocity.length() > 0 and current_speed > 0:
				velocity = velocity.normalized() * current_speed
			else:
				velocity = Vector2.ZERO
	
	move_and_slide()
	
	# Debug collision sticking
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_collider() is Enemy:
				var enemy = collision.get_collider()
				var distance = global_position.distance_to(enemy.global_position)
				# print("DEBUG: Player colliding with enemy - Player pos: ", global_position, " Enemy pos: ", enemy.global_position, " Distance: ", distance)
				
				# Apply separation force if too close and not dashing
				if distance < 30.0 and not is_dashing and not enemy.is_currently_dashing():
					var separation_direction = (global_position - enemy.global_position).normalized()
					var separation_force = separation_direction * 50.0  # Push away gently
					velocity += separation_force
					# print("DEBUG: Applying separation force to player: ", separation_force)

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
		var attack_direction = get_current_input_direction()
		
		# If no direction pressed, don't attack
		if attack_direction.length() > 0:
			perform_dash_attack(attack_direction)

func change_stance(new_stance: Stance):
	if current_stance != new_stance:
		# Handle direction preservation when changing stances
		handle_stance_direction_change(current_stance, new_stance)
		
		# Stop walking audio when entering combat stance
		if new_stance != Stance.NEUTRAL and is_walking_audio_playing:
			audio_manager.stop_walking_sound(walking_audio)
			is_walking_audio_playing = false
		
		previous_stance = current_stance
		current_stance = new_stance
		
		# Start parry window when entering non-neutral stance
		if new_stance != Stance.NEUTRAL:
			start_parry_window()
			# Show defense circles during combat stances
			if defense_circles:
				# print("DEBUG: Player changing to combat stance: ", Stance.keys()[new_stance], " - showing defense circles")
				defense_circles.show_defense_circles()
		else:
			stop_parry_window()
			# Hide defense circles when returning to neutral
			if defense_circles:
				# print("DEBUG: Player changing to NEUTRAL stance - hiding defense circles")
				defense_circles.hide_defense_circles()
		
		# Play stance change sound
		if audio_manager and walking_audio:
			audio_manager.play_stance_change_sfx(walking_audio)
		
		update_stance_visual()
		stance_changed.emit(current_stance)

func get_shortest_angle_difference(from_angle: float, to_angle: float) -> float:
	# Calculate the shortest angular difference between two angles
	# Returns a value between -180 and 180 degrees
	var difference = to_angle - from_angle
	
	# Normalize to [-180, 180] range
	while difference > 180:
		difference -= 360
	while difference < -180:
		difference += 360
	
	return difference

func start_screen_shake(intensity: float, duration: float):
	# Start screen shake with given intensity and duration
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration

func update_screen_shake(delta: float):
	# Update screen shake effect
	if shake_timer > 0:
		shake_timer -= delta
		
		# Calculate shake offset with decreasing intensity
		var shake_strength = shake_intensity * (shake_timer / shake_duration)
		var shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		
		# Apply shake to scene camera
		if scene_camera:
			scene_camera.position = base_camera_position + shake_offset
	else:
		# Return camera to base position when shake ends
		if scene_camera:
			scene_camera.position = base_camera_position

enum DamageCategory { NONE, LIGHT, NORMAL, HEAVY }

func get_damage_category(final_damage: int, original_damage: int) -> DamageCategory:
	# Categorize damage for appropriate visual feedback
	if final_damage <= 0:
		return DamageCategory.NONE  # Perfect block or tie
	elif final_damage <= 2 or original_damage != final_damage:  # Light damage or blocked
		return DamageCategory.LIGHT
	elif final_damage <= 4:
		return DamageCategory.NORMAL
	else:
		return DamageCategory.HEAVY  # 5+ damage

func show_damage_feedback(final_damage: int, original_damage: int):
	# Enhanced damage feedback system with categorized responses
	var category = get_damage_category(final_damage, original_damage)
	
	print("DEBUG: Damage feedback - Final:", final_damage, " Original:", original_damage, " Category:", category)
	
	# Apply visual feedback based on damage category
	apply_color_feedback(category)
	apply_blink_feedback(category)
	apply_screen_shake_by_category(category)
	
	# Spawn damage number
	spawn_damage_number(final_damage, category, final_damage == 0)

func spawn_damage_number(amount: int, category: DamageCategory, is_tie: bool = false):
	# Load and spawn damage number scene
	var damage_number_scene = preload("res://scenes/DamageNumber.tscn")
	var damage_number = damage_number_scene.instantiate()
	
	# Add to scene tree (parent to the main scene to avoid cleanup issues)
	get_tree().current_scene.add_child(damage_number)
	
	# Position above player with slight randomness
	var spawn_position = global_position + Vector2(randf_range(-15, 15), -30)
	
	# Show the damage number (player taking damage = red)
	damage_number.show_damage(amount, int(category), spawn_position, is_tie, true)

func apply_color_feedback(category: DamageCategory):
	# Apply color flash based on damage category
	var tween = create_tween()
	
	match category:
		DamageCategory.NONE:
			# White/silver flash for no damage
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
			tween.tween_property(sprite, "modulate", Color.LIGHT_GRAY, 0.1)
			tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		DamageCategory.LIGHT:
			# Light red flash for minimal damage
			tween.tween_property(sprite, "modulate", Color.ORANGE_RED, 0.1)
			tween.tween_property(sprite, "modulate", Color.LIGHT_CORAL, 0.1)
		DamageCategory.NORMAL:
			# Standard red flash
			tween.tween_property(sprite, "modulate", Color.RED, 0.1)
			tween.tween_property(sprite, "modulate", Color.PINK, 0.1)
		DamageCategory.HEAVY:
			# Intense red flash with longer duration
			tween.tween_property(sprite, "modulate", Color.DARK_RED, 0.15)
			tween.tween_property(sprite, "modulate", Color.RED, 0.15)
			tween.tween_property(sprite, "modulate", Color.PINK, 0.1)

func apply_blink_feedback(category: DamageCategory):
	# Apply appear/disappear blinking based on damage category
	var blink_tween = create_tween()
	
	match category:
		DamageCategory.NONE:
			# 1-2 quick blinks for no damage
			blink_tween.tween_property(sprite, "modulate:a", 0.2, 0.05)
			blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
			blink_tween.tween_property(sprite, "modulate:a", 0.2, 0.05)
			blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.05)
		DamageCategory.LIGHT:
			# 2-3 rapid blinks
			blink_tween.tween_property(sprite, "modulate:a", 0.3, 0.06)
			blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.06)
			blink_tween.tween_property(sprite, "modulate:a", 0.3, 0.06)
			blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.06)
			blink_tween.tween_property(sprite, "modulate:a", 0.3, 0.06)
			blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.06)
		DamageCategory.NORMAL:
			# 4-5 medium blinks with longer gaps
			for i in range(4):
				blink_tween.tween_property(sprite, "modulate:a", 0.2, 0.08)
				blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.12)
		DamageCategory.HEAVY:
			# 6-8 longer blinks with dramatic pauses
			for i in range(6):
				blink_tween.tween_property(sprite, "modulate:a", 0.1, 0.1)
				blink_tween.tween_property(sprite, "modulate:a", 1.0, 0.15)

func apply_screen_shake_by_category(category: DamageCategory):
	# Apply screen shake based on damage category
	match category:
		DamageCategory.NONE:
			# No shake for no damage
			pass
		DamageCategory.LIGHT:
			start_screen_shake(3.0, 0.15)  # Very light shake
		DamageCategory.NORMAL:
			start_screen_shake(8.0, 0.25)  # Medium shake
		DamageCategory.HEAVY:
			start_screen_shake(20.0, 0.5)  # Strong shake

func get_current_input_direction() -> Vector2:
	# Get current directional input (reused for dash attacks and stance rotation)
	var input_direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_direction.y -= 1
	if Input.is_action_pressed("move_down"):
		input_direction.y += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1
	
	return input_direction.normalized() if input_direction.length() > 0 else Vector2.ZERO

func has_any_input() -> bool:
	# Check if player is providing any input (movement or stance)
	var move_up = Input.is_action_pressed("move_up")
	var move_down = Input.is_action_pressed("move_down") 
	var move_left = Input.is_action_pressed("move_left")
	var move_right = Input.is_action_pressed("move_right")
	var rock = Input.is_action_pressed("gesture_rock")
	var paper = Input.is_action_pressed("gesture_paper")
	var scissors = Input.is_action_pressed("gesture_scissors")
	var attack = Input.is_action_pressed("attack")
	
	var has_input = move_up or move_down or move_left or move_right or rock or paper or scissors or attack
	
	# Debug which inputs are active (only when there are inputs)
	# if has_input:
	#	var active_inputs = []
	#	if move_up: active_inputs.append("UP")
	#	if move_down: active_inputs.append("DOWN")
	#	if move_left: active_inputs.append("LEFT")
	#	if move_right: active_inputs.append("RIGHT")
	#	if rock: active_inputs.append("ROCK")
	#	if paper: active_inputs.append("PAPER")
	#	if scissors: active_inputs.append("SCISSORS")
	#	if attack: active_inputs.append("ATTACK")
	#	print("DEBUG: Active inputs: ", active_inputs)
	#	pass
	
	return has_input

func handle_stance_direction_change(old_stance: Stance, new_stance: Stance):
	# Entering a stance from neutral - preserve current direction
	if old_stance == Stance.NEUTRAL and new_stance != Stance.NEUTRAL:
		# Use current sprite rotation if actively moving, otherwise use last movement direction
		if velocity.length() > movement_threshold:
			entering_stance_direction = sprite.rotation_degrees
		else:
			# Use last known movement direction when idle
			entering_stance_direction = last_movement_direction
		print("PLAYER: Entering stance ", Stance.keys()[new_stance], " - Position: ", global_position, " - Direction: ", entering_stance_direction)
	
	# Exiting stance back to neutral - restore preserved direction
	elif old_stance != Stance.NEUTRAL and new_stance == Stance.NEUTRAL:
		# Don't immediately restore here - let update_stance_visual handle it
		print("PLAYER: Exiting stance - Position: ", global_position, " - Restored direction: ", entering_stance_direction)

func update_stance_visual():
	# Update animation and scale based on stance
	match current_stance:
		Stance.NEUTRAL:
			# Check if moving to determine idle vs walking
			if velocity.length() > movement_threshold and not is_dashing and not is_stunned:
				sprite.play("walking")
				if eye_sprite:
					eye_sprite.visible = true
					eye_sprite.play("walking")
				current_animation_state = "walking"
			else:
				sprite.play("idle")
				if eye_sprite:
					eye_sprite.visible = true
					eye_sprite.play("idle")
				current_animation_state = "idle"
			
			# If we just exited a stance, restore the preserved direction
			if previous_stance != Stance.NEUTRAL:
				sprite.rotation_degrees = entering_stance_direction
				print("Restored direction after exiting stance: ", entering_stance_direction)
		Stance.ROCK:
			sprite.play("rock")
			if eye_sprite:
				eye_sprite.visible = false
			sprite.rotation_degrees = entering_stance_direction  # Preserve direction when entering stance
			sprite.position = base_position  # Reset position
			if rotation_tween: rotation_tween.kill()  # Stop any rotation tweens
			current_animation_state = "rock"
		Stance.PAPER:
			sprite.play("paper")
			if eye_sprite:
				eye_sprite.visible = false
			sprite.rotation_degrees = entering_stance_direction  # Preserve direction when entering stance
			sprite.position = base_position  # Reset position
			if rotation_tween: rotation_tween.kill()  # Stop any rotation tweens
			current_animation_state = "paper"
		Stance.SCISSORS:
			sprite.play("scissors")
			if eye_sprite:
				eye_sprite.visible = false
			sprite.rotation_degrees = entering_stance_direction  # Preserve direction when entering stance
			sprite.position = base_position  # Reset position
			if rotation_tween: rotation_tween.kill()  # Stop any rotation tweens
			current_animation_state = "scissors"
	
	# stance_label.text = stance_symbols[current_stance]  # Disabled stance emoji display

func update_animation_state(delta):
	# Handle animation transitions based on movement and state
	if is_stunned:
		return  # Don't change animations during stunned state
	
	# During dash, preserve current scale and animation
	if is_dashing:
		return  # Don't change animations or scale during dash
	
	if current_stance == Stance.NEUTRAL:
		var is_moving = velocity.length() > movement_threshold
		
		if is_moving and current_animation_state != "walking":
			sprite.play("walking")
			if eye_sprite:
				eye_sprite.visible = true
				eye_sprite.play("walking")
			current_animation_state = "walking"
			# Start walking audio
			if not is_walking_audio_playing:
				audio_manager.play_walking_sound(walking_audio)
				is_walking_audio_playing = true
		elif not is_moving and current_animation_state != "idle" and not is_in_long_idle:
			sprite.play("idle")
			if eye_sprite:
				eye_sprite.visible = true
				eye_sprite.play("idle")
			current_animation_state = "idle"
			# Stop walking audio
			if is_walking_audio_playing:
				audio_manager.stop_walking_sound(walking_audio)
				is_walking_audio_playing = false
	
	# Handle different animation states with appropriate scaling
	match current_animation_state:
		"idle":
			# Only modify base_scale if not dashing (prevents corruption)
			if not is_dashing:
				base_scale = Vector2(1.0, 1.0)
			
			# Simple static positioning and scaling (animation handled by spritesheet)
			sprite.position = base_position
			if not is_dashing:
				sprite.scale = base_scale
				if eye_sprite and eye_sprite.visible:
					eye_sprite.scale = sprite.scale * 0.5
			
		"long_idle":
			# Same as regular idle but for long idle animation
			if not is_dashing:
				base_scale = Vector2(1.0, 1.0)
			
			sprite.position = base_position
			if not is_dashing:
				sprite.scale = base_scale
			
		"walking":
			# Only modify base_scale if not dashing (prevents corruption)
			if not is_dashing:
				base_scale = Vector2(1.0, 1.0)
			sprite.position = base_position
			# Only set scale if not dashing (preserve scale during dash)
			if not is_dashing:
				sprite.scale = base_scale
				if eye_sprite and eye_sprite.visible:
					eye_sprite.scale = sprite.scale * 0.5
			
		"rock", "paper", "scissors":
			# Only modify base_scale if not dashing (prevents corruption)
			if not is_dashing:
				base_scale = Vector2(1.0, 1.0)
			sprite.position = base_position
			# Only set scale if not dashing (preserve scale during dash)
			if not is_dashing:
				sprite.scale = base_scale
			
			# Handle dynamic stance rotation based on input direction
			var input_direction = get_current_input_direction()
			if input_direction.length() > 0:
				# Player is indicating a dash direction - rotate to face it
				var input_angle = input_direction.angle()
				var target_rotation_degrees = rad_to_deg(input_angle) + 90  # Adjust for sprite orientation
				
				# Use shortest angle path for smooth stance rotation
				var angle_diff = get_shortest_angle_difference(sprite.rotation_degrees, target_rotation_degrees)
				if abs(angle_diff) > 5:  # Only rotate if significant change
					# Use normalized target to force short path in tween
					var normalized_target = sprite.rotation_degrees + angle_diff
					if rotation_tween:
						rotation_tween.kill()
					rotation_tween = create_tween()
					rotation_tween.tween_property(sprite, "rotation_degrees", normalized_target, stance_rotation_speed)
			# If no input direction, maintain current rotation (don't snap back)
	
	# Handle directional rotation for walking (top-down perspective)
	if current_animation_state == "walking" and velocity.length() > movement_threshold:
		var movement_angle = velocity.angle()
		var target_rotation_degrees = rad_to_deg(movement_angle) + 90  # Adjust for sprite orientation
		
		# Store the current movement direction for stance preservation
		last_movement_direction = target_rotation_degrees
		
		# Use shortest angle path for smooth rotation transition
		var angle_diff = get_shortest_angle_difference(sprite.rotation_degrees, target_rotation_degrees)
		if abs(angle_diff) > 5:  # Only rotate if significant change
			# Use normalized target to force short path in tween
			var normalized_target = sprite.rotation_degrees + angle_diff
			current_rotation = target_rotation_degrees  # Update tracking variable
			if rotation_tween:
				rotation_tween.kill()
			rotation_tween = create_tween()
			rotation_tween.tween_property(sprite, "rotation_degrees", normalized_target, 0.2)
	# Note: Removed auto-return to neutral rotation - hand maintains last direction when idle

func perform_dash_attack(direction: Vector2):
	# Preserve current scale before starting dash
	dash_preserved_scale = sprite.scale
	
	# Start the dash
	is_dashing = true
	dash_direction = direction
	dash_timer = dash_duration
	
	# Play attack sound
	if audio_manager and walking_audio:
		audio_manager.play_player_attack_sfx(walking_audio)
	
	# Start attack cooldown
	attack_cooldown_timer = attack_cooldown
	
	# Clear the list of enemies hit this dash
	enemies_hit_this_dash.clear()
	
	# No visual color change during dash - keep sprite color clean
	
	# Auto-return to neutral after dash
	var tween = create_tween()
	tween.tween_interval(dash_duration)
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
			# Light screen shake for successful hit
			start_screen_shake(8.0, 0.15)

func take_damage(amount: int):
	# Don't take damage if immune
	if is_immune:
		return
		
	# Players in neutral stance take reduced damage (25% of original damage)
	var original_damage = amount
	var final_damage = amount
	if current_stance == Stance.NEUTRAL:
		final_damage = max(1, amount / 4)  # 25% damage, minimum 1
		
	current_health = max(0, current_health - final_damage)
	health_changed.emit(current_health)
	
	# Play hit sound
	if audio_manager and walking_audio:
		audio_manager.play_player_hit_sfx(walking_audio)
	
	# Enhanced damage feedback system
	show_damage_feedback(final_damage, original_damage)
	
	# Start immunity frames
	is_immune = true
	immunity_timer = immunity_duration
	
	# Add immunity frame visual feedback (flickering) - keeping this separate
	var immunity_tween = create_tween()
	immunity_tween.tween_interval(0.4)  # Wait for main feedback to finish
	immunity_tween.tween_callback(func(): add_immunity_visual_feedback())
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)
	
	# Spawn healing number
	spawn_healing_number(amount)

func spawn_healing_number(amount: int):
	# Load and spawn damage number scene for healing
	var damage_number_scene = preload("res://scenes/DamageNumber.tscn")
	var damage_number = damage_number_scene.instantiate()
	
	# Add to scene tree
	get_tree().current_scene.add_child(damage_number)
	
	# Position above player
	var spawn_position = global_position + Vector2(0, -30)
	
	# Show the healing number
	damage_number.show_healing(amount, spawn_position)

func consume_defense_point() -> bool:
	if current_defense_points > 0:
		current_defense_points -= 1
		defense_points_changed.emit(current_defense_points, max_defense_points)
		# Update defense circles visual
		if defense_circles:
			defense_circles.update_defense_points(current_defense_points)
		# Play defense point consumed sound
		if audio_manager and walking_audio:
			audio_manager.play_defense_point_consumed_sfx(walking_audio)
		return true
	return false

func restore_defense_point():
	if current_defense_points < max_defense_points:
		current_defense_points += 1
		defense_points_changed.emit(current_defense_points, max_defense_points)
		# Update defense circles visual
		if defense_circles:
			defense_circles.update_defense_points(current_defense_points)
		# Play a positive feedback sound (could use perfect parry sound)
		if audio_manager and walking_audio:
			audio_manager.play_perfect_parry_sfx(walking_audio)

func consume_multiple_defense_points(amount: int) -> int:
	var consumed = min(amount, current_defense_points)
	if consumed > 0:
		current_defense_points -= consumed
		defense_points_changed.emit(current_defense_points, max_defense_points)
		# Update defense circles visual
		if defense_circles:
			defense_circles.update_defense_points(current_defense_points)
		# Play defense point consumed sound
		if audio_manager and walking_audio:
			audio_manager.play_defense_point_consumed_sfx(walking_audio)
	return consumed

func apply_stun():
	is_stunned = true
	stun_timer = stun_duration
	
	# Cancel any ongoing dash immediately
	if is_dashing:
		is_dashing = false
		dash_timer = 0.0
		velocity = Vector2.ZERO
		# Restore preserved scale when dash is cancelled by stun
		if dash_preserved_scale != Vector2.ZERO:
			sprite.scale = dash_preserved_scale
			dash_preserved_scale = Vector2.ZERO
	
	# Stop walking audio if playing
	if is_walking_audio_playing:
		audio_manager.stop_walking_sound(walking_audio)
		is_walking_audio_playing = false
	
	# Always change to neutral stance when stunned
	change_stance(Stance.NEUTRAL)
	
	# Ensure proper neutral scale during stun (fixes tiny sprite bug)
	sprite.scale = Vector2(1.0, 1.0)
	current_animation_state = "idle"
	
	# Play stun sound
	if audio_manager and walking_audio:
		audio_manager.play_player_stun_sfx(walking_audio)
	
	# Visual feedback for stun
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.PURPLE, 0.2)
	# Show stun indicator
	if stun_indicator:
		stun_indicator.visible = true
	print("Player stunned for ", stun_duration, " seconds!")

func die():
	print("Player died!")
	# Play death sound
	if audio_manager and walking_audio:
		audio_manager.play_player_death_sfx(walking_audio)
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

func start_parry_window():
	# Start the parry window timer and show visual indicator
	is_parry_window_active = true
	parry_window_timer = parry_window_duration
	if parry_circle:
		parry_circle.show_parry_circle()

func stop_parry_window():
	# Stop the parry window and hide visual indicator
	is_parry_window_active = false
	parry_window_timer = 0.0
	if parry_circle:
		parry_circle.hide_parry_circle()

func update_parry_window(delta):
	# Update parry window timer and visual feedback
	if is_parry_window_active and parry_window_timer > 0:
		parry_window_timer -= delta
		
		# Update visual indicator based on remaining time
		if parry_circle and parry_circle.visible:
			var time_ratio = parry_window_timer / parry_window_duration
			parry_circle.update_parry_visual(time_ratio)
		
		# Stop parry window when timer expires
		if parry_window_timer <= 0:
			stop_parry_window()

func is_in_parry_window() -> bool:
	# Check if player is currently in the parry window
	return is_parry_window_active and parry_window_timer > 0

func perfect_parry_success():
	# Called when a perfect parry is executed
	print("PERFECT PARRY!")
	# Add visual feedback - flash the parry circle bright
	if parry_circle:
		parry_circle.show_perfect_parry_flash()
	# Add screen shake for feedback
	start_screen_shake(12.0, 0.3)
	# V2: Restore defense point on perfect parry
	restore_defense_point()
	# Play perfect parry sound
	if audio_manager and walking_audio:
		audio_manager.play_perfect_parry_sfx(walking_audio)

func update_dash_preview():
	# Show simple dash line when in combat stance and ready to attack
	if not dash_preview:
		return
		
	# Only show dash preview if in combat stance, not stunned, not dashing, and cooldown ready
	if current_stance != Stance.NEUTRAL and not is_stunned and not is_dashing and attack_cooldown_timer <= 0:
		# Check if holding direction keys to determine if player wants to attack
		var input_direction = Vector2.ZERO
		if Input.is_action_pressed("move_up"):
			input_direction += Vector2.UP
		if Input.is_action_pressed("move_down"):
			input_direction += Vector2.DOWN
		if Input.is_action_pressed("move_left"):
			input_direction += Vector2.LEFT
		if Input.is_action_pressed("move_right"):
			input_direction += Vector2.RIGHT
		
		# Only show line when actively pressing direction keys
		if input_direction.length() > 0:
			# Calculate relative end position using actual player stats
			var dash_distance = dash_speed * dash_duration  # 600 * 0.3 = 180 pixels
			var relative_end = input_direction.normalized() * dash_distance
			dash_preview.show_simple_dash_line(relative_end)
		else:
			# Hide line when no direction is being pressed
			dash_preview.hide_dash_trajectory()
	else:
		# Hide trajectory if not in combat stance or conditions not met
		dash_preview.hide_dash_trajectory()

func update_attack_cooldown_bar_visibility():
	# Show attack cooldown bar while charging until it's full
	if attack_cooldown_bar:
		var is_charging = attack_cooldown_timer > 0
		
		attack_cooldown_bar.visible = is_charging

func update_long_idle_timer(delta):
	# Check if player is truly idle (no movement, no input, in neutral stance)
	var is_truly_idle = current_stance == Stance.NEUTRAL and \
						velocity.length() <= movement_threshold and \
						not has_any_input() and \
						not is_dashing and \
						not is_stunned
	
	# Debug logging every 2 seconds (reduced verbosity)
	# if int(idle_timer) % 2 == 0 and idle_timer > 0 and idle_timer < 6:
	#	print("DEBUG: Long idle timer: ", idle_timer, " - Truly idle: ", is_truly_idle)
	#	pass
	
	if is_truly_idle:
		idle_timer += delta
		# Trigger long idle animation after delay
		if idle_timer >= long_idle_delay and not is_in_long_idle:
			# print("DEBUG: Triggering long idle animation at timer: ", idle_timer)
			trigger_long_idle()
	else:
		# Reset timer and exit long idle if any activity detected
		if idle_timer > 0:
			# print("DEBUG: Resetting idle timer - was: ", idle_timer)
			pass
		idle_timer = 0.0
		if is_in_long_idle:
			exit_long_idle()

func trigger_long_idle():
	# Play the long idle animation once
	# print("DEBUG: Long idle triggered! Setting animation to 'long_idle'")
	is_in_long_idle = true
	sprite.play("long_idle")
	current_animation_state = "long_idle"
	
func exit_long_idle():
	# Return to normal idle animation
	is_in_long_idle = false
	sprite.play("idle")
	current_animation_state = "idle"

func sync_eye_sprite_rotation():
	# Sync eye sprite rotation and position with main sprite rotation
	if eye_sprite and eye_sprite.visible:
		eye_sprite.rotation_degrees = sprite.rotation_degrees
		# Apply 3 pixel left offset that rotates with the sprite
		var offset = Vector2(-3, 0).rotated(deg_to_rad(sprite.rotation_degrees))
		eye_sprite.position = sprite.position + offset

func _on_animation_finished():
	# Handle when long idle animation finishes (returns to normal idle)
	if current_animation_state == "long_idle":
		exit_long_idle()
