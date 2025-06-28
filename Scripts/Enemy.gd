extends CharacterBody2D
class_name Enemy

# === ENEMY DATA RESOURCE ===
@export var enemy_data: EnemyData
var default_data: EnemyData  # Fallback if no resource assigned

# AI and movement variables (loaded from resource)
var speed: float = GameConstants.ENEMY_SPEED
var detection_range: float = GameConstants.BASE_DETECTION_RADIUS
var attack_range: float = GameConstants.ATTACK_RANGE
var dash_speed: float = GameConstants.ENEMY_DASH_SPEED
var dash_duration: float = GameConstants.ENEMY_DASH_DURATION

# Debug/Testing variables
@export var debug_rock_only: bool = false  # Use CSV-based stance probabilities

# Combat variables  
enum Stance { NEUTRAL, ROCK, PAPER, SCISSORS }
var current_stance: Stance = Stance.NEUTRAL  # Start in neutral like player
var max_health: int = GameConstants.ENEMY_MAX_HEALTH
var current_health: int = GameConstants.ENEMY_MAX_HEALTH

# Defense point system
var max_defense_points: int = GameConstants.ENEMY_MAX_DEFENSE_POINTS
var current_defense_points: int = GameConstants.ENEMY_MAX_DEFENSE_POINTS

# AI State - Enhanced tactical system
enum AIState { IDLE, WALKING, LOST_PLAYER, ALERT, OBSERVING, POSITIONING, STANCE_SELECTION, ATTACKING, RETREATING, STUNNED }
var current_state: AIState = AIState.WALKING
var player_ref: Player = null

# Attack system mirroring player
var attack_cooldown: float = GameConstants.ENEMY_ATTACK_COOLDOWN  # Slightly longer than player
var attack_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0

# Tactical AI variables
var stance_decision_timer: float = 0.0
var positioning_timer: float = 0.0
var retreat_timer: float = 0.0
var last_player_stance: Player.Stance = Player.Stance.NEUTRAL
var stance_change_cooldown: float = GameConstants.STANCE_CHANGE_COOLDOWN
var stance_change_timer: float = 0.0
var stance_to_dash_delay: float = GameConstants.STANCE_TO_DASH_DELAY  # 1 second delay after stance change (reduced for testing)
var stance_to_dash_timer: float = 0.0
var target_attack_position: Vector2  # Store player position when stance is selected

# Walking state variables
var walking_direction: Vector2 = Vector2.ZERO
var walking_timer: float = 0.0
var walking_speed: float = GameConstants.ENEMY_WALKING_SPEED  # Slower than normal speed
var direction_change_interval: float = GameConstants.DIRECTION_CHANGE_INTERVAL  # Change direction every 2.5 seconds

# Movement interpolation (like player)
var acceleration: float = GameConstants.ENEMY_ACCELERATION  # Slower than player for more deliberate movement
var deceleration: float = GameConstants.ENEMY_DECELERATION  # Quicker stopping
var current_speed: float = 0.0  # Current movement speed

# Rotation system (like player)
var current_rotation: float = 0.0
var rotation_tween: Tween
var last_movement_direction: float = 0.0

# Animation state tracking (like player)
var current_animation_state: String = "idle"
var movement_threshold: float = GameConstants.ENEMY_MOVEMENT_THRESHOLD  # Minimum velocity for rotation

# Debug output control
var debug_timer: float = 0.0
var debug_interval: float = GameConstants.DEBUG_INTERVAL  # Print debug every 1.0 seconds

# Idle and lost player state variables
var idle_timer: float = 0.0
var idle_duration_min: float = GameConstants.IDLE_DURATION_MIN  # Doubled from 1.0
var idle_duration_max: float = GameConstants.IDLE_DURATION_MAX  # Doubled from 3.0
var lost_player_timer: float = 0.0
var lost_player_duration: float = GameConstants.LOST_PLAYER_DURATION  # Time spent confused before giving up

# Alert state variables
var alert_timer: float = 0.0
var alert_duration: float = GameConstants.ALERT_DURATION  # 1 second alert display
var is_alerting: bool = false

# Immunity frames to prevent multiple hits
@export var immunity_duration: float = GameConstants.IMMUNITY_DURATION
var immunity_timer: float = 0.0
var is_immune: bool = false

# Stun system (enhanced existing STUNNED state)
@export var stun_duration: float = GameConstants.STUN_DURATION
var stun_timer: float = 0.0

# Track which players have been hit during current dash
var players_hit_this_dash: Array[Node] = []

# References
@onready var sprite: AnimatedSprite2D = $Sprite
# eye_sprite reference removed for complete overhaul
@onready var stance_label: Label = $StanceLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var defense_point_label: Label = $DefensePoint
@onready var stun_indicator: Label = $StunIndicator
@onready var lost_indicator: Label = $LostIndicator
@onready var alert_indicator: Label = $AlertIndicator
@onready var vision_cast: RayCast2D = $VisionCast
@onready var attack_area: Area2D = $AttackArea
@onready var audio_player: AudioStreamPlayer2D = $AudioPlayer
@onready var attack_timer_bar: ProgressBar = $AttackTimerBar
# dash_preview reference removed for complete overhaul

# Audio management
var audio_manager: AudioManager

# Debug visualization
var debug_detection_range: bool = false  # Detection range circles disabled
var debug_attack_range: bool = false  # Attack collision circles disabled
var base_detection_radius: float = GameConstants.BASE_DETECTION_RADIUS  # Normal detection range
var enhanced_detection_radius: float = GameConstants.ENHANCED_DETECTION_RADIUS  # When player is spotted (double size)
var current_detection_radius: float = GameConstants.BASE_DETECTION_RADIUS  # Current radius for drawing

# Vision system
var facing_direction: Vector2 = Vector2(1, 0)  # Default facing right
var last_player_position: Vector2 = Vector2.ZERO
var vision_timer: float = 0.0
var vision_check_interval: float = GameConstants.VISION_CHECK_INTERVAL  # Check vision 10 times per second

# Stance colors and symbols (enemy uses all stances tactically)
var stance_colors = {
	Stance.NEUTRAL: Color.LIGHT_GRAY,
	Stance.ROCK: Color.DARK_RED,
	Stance.PAPER: Color.PINK,
	Stance.SCISSORS: Color.ORANGE
}

var stance_symbols = {
	Stance.NEUTRAL: "👤",
	Stance.ROCK: "✊",
	Stance.PAPER: "✋", 
	Stance.SCISSORS: "✌️"
}

signal enemy_died
signal enemy_attack(attacker_stance: Stance, attack_position: Vector2)
signal enemy_defense_points_changed(current_defense: int, max_defense: int)

func load_enemy_data():
	# Load variables from EnemyData resource or create default values
	
	# Create default data if no resource assigned
	if not enemy_data:
		print("Warning: No EnemyData resource assigned to ", name, ". Using default values.")
		enemy_data = create_default_enemy_data()
	
	# Validate the data
	if not enemy_data.validate_data():
		print("Warning: Invalid data in EnemyData resource. Some values may be incorrect.")
	
	# Apply the loaded data
	apply_enemy_data()

func create_default_enemy_data() -> EnemyData:
	# Create default EnemyData if none assigned
	var data = EnemyData.new()
	data.enemy_name = "Default Enemy"
	# All other values will use the defaults from EnemyData.gd
	return data

func apply_collision_settings():
	# Apply collision settings from enemy data to the actual collision shapes
	# Apply body collision size
	var body_collision = get_node("CollisionShape2D")
	if body_collision and body_collision.shape is RectangleShape2D:
		var rect_shape = body_collision.shape as RectangleShape2D
		rect_shape.size = enemy_data.body_collision_size
	
	# Apply attack collision settings
	var attack_collision = attack_area.get_child(0) as CollisionShape2D
	if attack_collision and attack_collision.shape is CircleShape2D:
		var circle_shape = attack_collision.shape as CircleShape2D
		circle_shape.radius = enemy_data.attack_radius
		attack_collision.scale = enemy_data.attack_collision_scale

func apply_visual_data():
	# Apply visual customization from enemy data with dual sprite animations
	if not enemy_data:
		return
	
	# Get base animated sprite node only
	var sprite_node = get_node("Sprite") as AnimatedSprite2D
	
	if not sprite_node:
		print("ERROR: No base AnimatedSprite2D node found")
		return
	
	# Create SpriteFrames for base sprite (idle, walk only)
	setup_base_animations(sprite_node)
	
	# Apply scale to sprite
	sprite_node.scale = enemy_data.sprite_scale
	
	# Apply color tint to sprite
	sprite_node.modulate = enemy_data.color_tint
	
	# Start with appropriate animation
	sprite_node.play("idle")
	
	# Visual data applied successfully

func setup_base_animations(sprite_node: AnimatedSprite2D):
	# Create SpriteFrames for base sprite (idle, walk animations only)
	var sprite_frames = SpriteFrames.new()
	
	# Load base animation spritesheets
	var idle_texture = preload("res://assets/assets_game/enemy_idle.png")
	var walk_texture = preload("res://assets/assets_game/enemy_walk.png")
	
	# Add animations to SpriteFrames
	add_spritesheet_frames(sprite_frames, "idle", idle_texture, 64, 64)
	add_spritesheet_frames(sprite_frames, "walk", walk_texture, 64, 64)
	
	# Apply the SpriteFrames to the base sprite
	sprite_node.sprite_frames = sprite_frames
	
	# Base animations ready

# Eye animation setup removed for complete overhaul

func add_spritesheet_frames(sprite_frames: SpriteFrames, animation_name: String, texture: Texture2D, frame_width: int, frame_height: int):
	# Extract frames from a spritesheet and add them to SpriteFrames
	if not texture:
		print("ERROR: No texture provided for animation: ", animation_name)
		return
	
	# Create the animation
	sprite_frames.add_animation(animation_name)
	
	# Calculate frames in the spritesheet
	var texture_width = texture.get_width()
	var texture_height = texture.get_height()
	var frames_x = texture_width / frame_width
	var frames_y = texture_height / frame_height
	
	# Animation setup: frames_x × frames_y
	
	# Extract each frame
	for y in frames_y:
		for x in frames_x:
			# Create AtlasTexture for this frame
			var atlas_texture = AtlasTexture.new()
			atlas_texture.atlas = texture
			atlas_texture.region = Rect2(x * frame_width, y * frame_height, frame_width, frame_height)
			
			# Add frame to animation
			sprite_frames.add_frame(animation_name, atlas_texture)
	
	# Set animation properties
	sprite_frames.set_animation_speed(animation_name, 8.0)  # 8 FPS
	sprite_frames.set_animation_loop(animation_name, true)
	
	# Animation frames loaded successfully

func apply_enemy_data():
	# Apply enemy data to all relevant systems
	if not enemy_data:
		return
	
	# Load basic stats
	max_health = enemy_data.max_health
	current_health = max_health
	max_defense_points = enemy_data.max_defense_points
	current_defense_points = max_defense_points
	
	# Load movement variables
	speed = enemy_data.speed
	dash_speed = enemy_data.dash_speed
	dash_duration = enemy_data.dash_duration
	
	# Load detection variables
	detection_range = enemy_data.detection_range
	enhanced_detection_radius = enemy_data.enhanced_detection_radius
	
	# Load combat variables
	attack_cooldown = enemy_data.attack_cooldown
	attack_range = enemy_data.attack_range
	stun_duration = enemy_data.stun_duration
	
	# Load AI timing variables
	stance_to_dash_delay = enemy_data.get_aggression_modified_timer(enemy_data.stance_to_dash_delay)
	stance_decision_timer = enemy_data.get_aggression_modified_timer(enemy_data.stance_decision_timer)
	retreat_timer = enemy_data.get_aggression_modified_timer(enemy_data.retreat_timer)
	
	# Load idle timing (fixed duration, no aggression modifier for consistent idle behavior)
	idle_duration_min = enemy_data.idle_duration
	idle_duration_max = enemy_data.idle_duration  # Same value for fixed duration
	
	# Apply collision settings
	apply_collision_settings()
	
	# Apply visual settings
	apply_visual_data()
	
	# Emit defense points changed signal
	enemy_defense_points_changed.emit(current_defense_points, max_defense_points)
	
	print("Applied enemy data: ", enemy_data.enemy_name, " (", enemy_data.get_archetype_description(), ")")


func _ready():
	# Enemy initialization
	
	# Initialize audio manager
	audio_manager = AudioManager.new()
	
	# Initialize rotation tween (like player)
	rotation_tween = create_tween()
	rotation_tween.kill()  # Stop it initially
	
	# Load enemy data from resource
	if enemy_data:
		# Apply enemy data from resource
		apply_enemy_data()
	else:
		print("No enemy_data found, loading defaults...")
		load_enemy_data()
	
	# Dash preview initialization removed for complete overhaul
	
	update_visual()
	
	# Initialization complete
	
	# Setup vision casting (no signal connections needed for raycasting)
	if vision_cast:
		vision_cast.collision_mask = enemy_data.vision_collision_mask if enemy_data else 2
		vision_cast.enabled = true
	
	# Get player reference for vision system
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	# Emit initial defense points
	enemy_defense_points_changed.emit(current_defense_points, max_defense_points)
	
	# Enable debug drawing
	if debug_detection_range:
		queue_redraw()
	
	# Always redraw to show attack area during debugging
	queue_redraw()
	
	# Enable collision shape debugging
	# get_tree().debug_collisions_hint = true
	
	# Debug print collision sizes
	# print_collision_debug()
	
	# Fix collision layer setup
	# fix_collision_layers()
	
	# Fix attack area size - it's way too small!
	# fix_attack_area_size()
	
	# Initialize walking behavior
	WalkingState.pick_new_walking_direction(self)
	walking_timer = direction_change_interval
	
	# Ensure indicators start hidden
	if stun_indicator:
		stun_indicator.visible = false
	if lost_indicator:
		lost_indicator.visible = false
	if alert_indicator:
		alert_indicator.visible = false
	if attack_timer_bar:
		attack_timer_bar.visible = false
	
func _physics_process(delta):
	# Enemy dashing logic handled in handle_dash_movement()
	
	# Update AI state management FIRST (allows proper state transitions like WALKING → IDLE)
	update_ai(delta)
	
	# Update vision detection system SECOND (respects state changes made by AI system)
	vision_timer += delta
	if vision_timer >= vision_check_interval:
		vision_timer = 0.0
		update_vision_detection()
	update_timers(delta)
	handle_dash_movement(delta)
	
	# Update immunity frames
	if immunity_timer > 0:
		immunity_timer -= delta
		if immunity_timer <= 0:
			is_immune = false
			# Reset visual feedback when immunity ends
			sprite.modulate = Color.WHITE

func update_ai(delta):
	if is_dashing:
		return  # Don't update AI during dash
		
	# Note: All movement functions now enforce neutral stance restriction like player
	match current_state:
		AIState.IDLE:
			IdleState.update_idle_state(self, delta)
		
		AIState.WALKING:
			WalkingState.update_walking_state(self, delta)
		
		AIState.LOST_PLAYER:
			# Stand still and look confused
			velocity = Vector2.ZERO
			current_stance = Stance.NEUTRAL
			# Check if confusion time is over
			if WalkingState.should_return_to_walking_from_lost_player(self):
				WalkingState.transition_from_lost_player_to_walking(self)
		
		AIState.ALERT:
			AlertState.update_alert_state(self, delta)
			
		AIState.OBSERVING:
			ObservingState.update_observing_state(self, delta)
			
		AIState.POSITIONING:
			PositioningState.update_positioning_state(self, delta)
			
		AIState.STANCE_SELECTION:
			StanceSelectionState.update_stance_selection_state(self, delta)
			
		AIState.ATTACKING:
			AttackingState.update_attacking_state(self, delta)
				
		AIState.RETREATING:
			RetreatingState.update_retreating_state(self, delta)
				
		AIState.STUNNED:
			StunnedState.update_stunned_state(self, delta)
	
	# Movement is now handled in handle_dash_movement() during dashes
	if not is_dashing:
		move_and_slide()
		
		# Debug collision sticking
		if get_slide_collision_count() > 0:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				if collision.get_collider() is Player:
					var player = collision.get_collider()
					var distance = global_position.distance_to(player.global_position)
					
					# Apply separation force if too close and not dashing
					if distance < GameConstants.SEPARATION_DISTANCE_THRESHOLD and not is_dashing and not player.is_currently_dashing():
						var separation_direction = (global_position - player.global_position).normalized()
						var separation_force = separation_direction * GameConstants.ENEMY_SEPARATION_FORCE  # Push away gently
						velocity += separation_force


func is_near_boundary() -> bool:
	return is_position_near_boundary(global_position)

func is_position_near_boundary(pos: Vector2) -> bool:
	# Check if position is near arena boundaries (with some margin)
	var margin = GameConstants.BOUNDARY_MARGIN
	return pos.x < GameConstants.LEVEL_BOUNDARY_LEFT + margin or pos.x > GameConstants.LEVEL_BOUNDARY_RIGHT - margin or pos.y < GameConstants.LEVEL_BOUNDARY_TOP + margin or pos.y > GameConstants.LEVEL_BOUNDARY_BOTTOM - margin

# New AI methods for tactical combat

func chase_player():
	if player_ref:
		# Only move if in neutral stance (like player)
		if current_stance != Stance.NEUTRAL:
			apply_movement_with_rotation(Vector2.ZERO)
			return
			
		var direction = (player_ref.global_position - global_position).normalized()
		apply_movement_with_rotation(direction * speed)


func handle_dash_movement(delta):
	# No dash movement allowed when stunned
	if StunnedState.prevent_dash_movement_when_stunned(self):
		return
	
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			velocity = Vector2.ZERO
			# Auto-return to neutral after dash like player
			current_stance = Stance.NEUTRAL
			update_visual()
			current_state = AIState.RETREATING
			retreat_timer = GameConstants.RETREAT_TIMER
			# Hide debug attack range when dash ends
			if debug_attack_range:
				queue_redraw()
		else:
			velocity = dash_direction * dash_speed
			
		# CRITICAL FIX: Apply movement during dash
		move_and_slide()
		
		# Debug collision sticking during dash
		if get_slide_collision_count() > 0:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				if collision.get_collider() is Player:
					pass
			
		# Check for player hits during dash
		AttackingState.attack_during_dash(self)



func calculate_damage(attacker_stance: Stance, defender_stance: Stance) -> int:
	# Rock-Paper-Scissors logic
	if attacker_stance == defender_stance:
		return 10  # Tie damage
	elif (attacker_stance == Stance.ROCK and defender_stance == Stance.SCISSORS) or \
		 (attacker_stance == Stance.PAPER and defender_stance == Stance.ROCK) or \
		 (attacker_stance == Stance.SCISSORS and defender_stance == Stance.PAPER):
		return 30  # Win damage
	else:
		return 5   # Lose damage

func calculate_combat_damage(enemy_stance: Stance, player_stance, is_mutual_attack: bool = false) -> Dictionary:
	# Use centralized combat calculator
	var combat_result = CombatCalculator.resolve_combat(enemy_stance, player_stance, is_mutual_attack)
	
	# Convert CombatCalculator result format to legacy format for compatibility
	var result = {
		"damage": combat_result.damage,
		"enemy_stunned": combat_result.attacker_stunned,
		"player_defense_consumed": combat_result.defender_defense_consumed,
		"weak_stance_damage": combat_result.weak_stance_damage
	}
	
	# Handle perfect parry logic (only for attack vs defense, not mutual attacks)
	if not is_mutual_attack and result.damage == 0 and not result.player_defense_consumed:
		# Check if player is in parry window for perfect parry
		var player_ref = get_tree().get_first_node_in_group("player")
		if player_ref and player_ref.has_method("is_in_parry_window") and player_ref.is_in_parry_window():
			# Perfect parry! Stun enemy
			result.enemy_stunned = true
			# Trigger perfect parry feedback on player
			if player_ref.has_method("perfect_parry_success"):
				player_ref.perfect_parry_success()
			print("Perfect parry! Enemy stunned!")
		else:
			# Regular successful block - consume defense point instead
			result.player_defense_consumed = true
			print("Successful block outside parry window - defense point consumed")
	
	return result

func take_damage_from_player(player_stance, attack_position: Vector2, is_mutual_attack: bool = false):
	# Use centralized combat calculator - player attacking enemy
	var combat_result = CombatCalculator.resolve_combat(player_stance, current_stance, is_mutual_attack)
	
	var damage = combat_result.damage
	var result = combat_result.result_description
	var player_stunned = combat_result.attacker_stunned
	var enemy_defense_consumed = combat_result.defender_defense_consumed
	
	# Handle defense point consumption
	if enemy_defense_consumed:
		if consume_defense_point():
			print("Enemy blocked with defense point!")
		else:
			# No defense points left, take damage instead (reduced for same-stance balance)
			damage = 1
			take_damage(damage)
	elif damage > 0:
		take_damage(damage)
	
	# Handle player stun (enemy successfully parried!)
	if player_stunned:
		var player_ref = get_tree().get_first_node_in_group("player")
		if player_ref and player_ref.has_method("apply_stun"):
			player_ref.apply_stun()
	
	# Debug: Combat result calculated
	print("Combat result: ", result)

func spawn_damage_number(amount: int):
	# Load and spawn damage number scene for enemy taking damage (blue numbers)
	var damage_number_scene = preload("res://scenes/DamageNumber.tscn")
	var damage_number = damage_number_scene.instantiate()
	
	# Add to scene tree
	get_tree().current_scene.add_child(damage_number)
	
	# Position above enemy with slight randomness
	var spawn_position = global_position + Vector2(randf_range(-15, 15), -30)
	
	# Determine damage category for blue coloring
	var category = 2  # Default to NORMAL category
	if amount <= 2:
		category = 1  # LIGHT
	elif amount <= 4:
		category = 2  # NORMAL
	else:
		category = 3  # HEAVY
	
	# Show blue damage number (is_player_taking_damage = false)
	damage_number.show_damage(amount, category, spawn_position, false, false)

func take_damage(amount: int):
	# Don't take damage if immune
	if is_immune:
		return
		
	current_health = max(0, current_health - amount)
	update_health_bar()
	
	# Play hit sound
	if audio_manager and audio_player:
		audio_manager.play_enemy_hit_sfx(audio_player)
	
	# Spawn blue damage number (player dealing damage to enemy)
	spawn_damage_number(amount)
	
	# Start immunity frames
	is_immune = true
	immunity_timer = immunity_duration
	
	# Visual feedback for taking damage
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.PINK, 0.1)
	
	# Add immunity frame visual feedback (flickering)
	tween.tween_callback(func(): add_immunity_visual_feedback())
	
	if current_health <= 0:
		die()
	else:
		# Brief stun when taking damage
		current_state = AIState.STUNNED
		var stun_timer = create_tween()
		stun_timer.tween_callback(func(): _set_retreating_state()).set_delay(0.5)

func _set_retreating_state():
	current_state = AIState.RETREATING
	retreat_timer = GameConstants.RETREAT_TIMER

func update_timers(delta):
	# Update debug timer for controlled output
	debug_timer += delta
	if debug_timer >= debug_interval:
		debug_timer = 0.0
		# Debug output removed for performance
	
	# Update attack cooldown in all states for responsive combat
	if attack_timer > 0:
		attack_timer -= delta
		
	if stance_change_timer > 0:
		stance_change_timer -= delta
		
	if stance_decision_timer > 0:
		stance_decision_timer -= delta
		
	if positioning_timer > 0:
		positioning_timer -= delta
		
	if retreat_timer > 0:
		retreat_timer -= delta
		
	# Update stance-to-dash delay timer
	if stance_to_dash_timer > 0:
		stance_to_dash_timer -= delta
		
		# Update attack timer bar during ATTACKING state
		if current_state == AIState.ATTACKING and attack_timer_bar:
			attack_timer_bar.visible = true
			var progress = 1.0 - (stance_to_dash_timer / stance_to_dash_delay)
			attack_timer_bar.value = progress
			
			# Color feedback: Red while charging, Green when about to attack
			if stance_to_dash_timer > 0.5:
				attack_timer_bar.modulate = Color.RED
			else:
				attack_timer_bar.modulate = Color.ORANGE
	else:
		# Hide timer bar when not in attacking countdown
		if attack_timer_bar and current_state != AIState.ATTACKING:
			attack_timer_bar.visible = false
	
	# Update stun timer
	if stun_timer > 0:
		stun_timer -= delta
		if stun_timer <= 0:
			# Hide stun indicator when timer ends
			if stun_indicator:
				stun_indicator.visible = false
	
	# Update walking timer
	if walking_timer > 0:
		walking_timer -= delta
	
	# Update idle timer
	if idle_timer > 0:
		idle_timer -= delta
	
	# Update lost player timer
	if lost_player_timer > 0:
		lost_player_timer -= delta
		if current_state == AIState.LOST_PLAYER:
			pass
	
	# Update alert timer
	if alert_timer > 0:
		alert_timer -= delta

func update_visual():
	# Debug output removed for performance
	
	# Handle stance-based sprite display only during stance selection and pre-attack phase
	if current_stance != Stance.NEUTRAL and current_state == AIState.STANCE_SELECTION:
		# Show stance-specific static sprite during stance selection only
		show_stance_sprite()
	else:
		# Show animated sprites in all other cases (including ATTACKING with neutral stance)
		restore_animated_sprites()
		# Handle normal animation logic
		update_animated_sprites()
	
	# Rotation is now integrated with movement functions
	
	# stance_label.text = stance_symbols[current_stance]  # Disabled stance emoji display
	update_health_bar()
	update_defense_point_visual()

func update_animated_sprites():
	# Update base sprite animation and track animation state
	if sprite and sprite.sprite_frames:
		# IMPORTANT: Respect idle timer protection (prevent interrupting 3-second idle animation)
		if IdleState.should_maintain_idle_animation(self):
			# Don't change animation during protected idle period
			if sprite.animation != "idle":
				sprite.play("idle")
			current_animation_state = "idle"
			return
			
		match current_state:
			AIState.IDLE, AIState.STUNNED, AIState.POSITIONING, AIState.STANCE_SELECTION:
				if sprite.animation != "idle":
					sprite.play("idle")
				current_animation_state = "idle"
			AIState.WALKING, AIState.LOST_PLAYER, AIState.RETREATING, AIState.ATTACKING:
				if sprite.animation != "walk":
					sprite.play("walk")
				current_animation_state = "walking"
			AIState.ALERT, AIState.OBSERVING:
				# Base sprite still shows walk animation
				if sprite.animation != "walk":
					sprite.play("walk")
				current_animation_state = "walking"
	
	# Eye sprite control removed for complete overhaul

func show_stance_sprite():
	# Create SpriteFrames with stance texture for AnimatedSprite2D compatibility
	var stance_texture: Texture2D
	match current_stance:
		Stance.ROCK:
			stance_texture = preload("res://assets/test_sprites/rock_enemy.png")
		Stance.PAPER:
			stance_texture = preload("res://assets/test_sprites/paper_enemy.png")
		Stance.SCISSORS:
			stance_texture = preload("res://assets/test_sprites/scissor_enemy.png")
	
	if stance_texture and sprite:
		# Create temporary SpriteFrames with single frame for stance display
		var stance_sprite_frames = SpriteFrames.new()
		stance_sprite_frames.add_animation("stance")
		stance_sprite_frames.add_frame("stance", stance_texture)
		stance_sprite_frames.set_animation_loop("stance", false)
		
		# Apply stance SpriteFrames
		sprite.sprite_frames = stance_sprite_frames
		sprite.animation = "stance"
		sprite.frame = 0
		sprite.visible = true

func restore_animated_sprites():
	# Restore sprite frames for animations when returning to neutral
	if sprite:
		setup_base_animations(sprite)  # Restore animation frames
		sprite.visible = true
	
	# Eye sprite restoration removed for complete overhaul

# Old separate rotation function removed - rotation is now integrated with movement

# Eye sprite rotation sync removed for complete overhaul

func apply_movement_with_rotation(new_velocity: Vector2):
	# Integrated movement and rotation system (like player)
	velocity = new_velocity
	
	# Apply rotation immediately if movement is significant
	if velocity.length() > movement_threshold:
		if not sprite:
			return
			
		var movement_angle = velocity.angle()
		var target_rotation_degrees = rad_to_deg(movement_angle) + 90  # Start at 90 degrees as requested
		
		# Store the current movement direction for stance preservation
		last_movement_direction = target_rotation_degrees
		
		# Use shortest angle path for smooth rotation transition
		var angle_diff = get_shortest_angle_difference(sprite.rotation_degrees, target_rotation_degrees)
		if abs(angle_diff) > 5:  # Only rotate if significant change
			var normalized_target = sprite.rotation_degrees + angle_diff
			current_rotation = target_rotation_degrees
			if rotation_tween:
				rotation_tween.kill()
			rotation_tween = create_tween()
			rotation_tween.tween_property(sprite, "rotation_degrees", normalized_target, 0.2)
			
			# Sync eye sprite rotation with main sprite (if eye sprite exists)
			var eye_sprite_node = get_node("EyeSprite") if has_node("EyeSprite") else null
			if eye_sprite_node:
				eye_sprite_node.rotation_degrees = normalized_target

func get_shortest_angle_difference(current_angle: float, target_angle: float) -> float:
	# Calculate shortest path between angles (like player)
	var diff = target_angle - current_angle
	while diff > 180:
		diff -= 360
	while diff < -180:
		diff += 360
	return diff

func print_enemy_status_debug():
	# Debug output optimized for performance
	pass

func update_health_bar():
	var health_percent = float(current_health) / float(max_health) * 100.0
	health_bar.value = health_percent
	
	# Change health bar color based on health
	if health_percent > 66:
		health_bar.modulate = Color.GREEN
	elif health_percent > 33:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.RED

func update_defense_point_visual():
	if defense_point_label:
		if current_defense_points > 0:
			defense_point_label.text = "🛡️"
			defense_point_label.modulate = Color.WHITE
		else:
			defense_point_label.text = "💔"
			defense_point_label.modulate = Color.GRAY

func consume_defense_point() -> bool:
	if current_defense_points > 0:
		current_defense_points -= 1
		enemy_defense_points_changed.emit(current_defense_points, max_defense_points)
		update_defense_point_visual()
		return true
	return false

func apply_stun():
	current_state = AIState.STUNNED
	stun_timer = stun_duration
	
	# Cancel any ongoing dash immediately
	if is_dashing:
		is_dashing = false
		dash_timer = 0.0
		velocity = Vector2.ZERO
	
	# Change to neutral stance when stunned
	current_stance = Stance.NEUTRAL
	update_visual()
	
	# Hide all other indicators when stunned
	hide_all_indicators()
	
	# Play stun sound
	if audio_manager and audio_player:
		audio_manager.play_enemy_stun_sfx(audio_player)
	
	# Visual feedback for stun
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.PURPLE, 0.2)
	# Show stun indicator
	if stun_indicator:
		stun_indicator.visible = true
	print("Enemy stunned for ", stun_duration, " seconds!")

func die():
	print("Enemy died!")
	# Play death sound and delay destruction to allow sound to play
	if audio_manager and audio_player:
		audio_manager.play_enemy_death_sfx(audio_player)
	
	enemy_died.emit()
	
	# Add a small delay before destroying the node to allow death sound to play
	var death_timer = create_tween()
	death_timer.tween_interval(0.5)  # Wait 0.5 seconds
	death_timer.tween_callback(queue_free)

func hide_all_indicators():
	if alert_indicator:
		alert_indicator.visible = false
	if lost_indicator:
		lost_indicator.visible = false
	# Don't hide stun indicator - it should only be controlled by stun system

func _draw():
	# Draw debug detection circle
	if debug_detection_range:
		# Change color based on detection state - orange when enhanced
		var circle_color = Color(1, 0, 0, 0.1) if current_detection_radius == base_detection_radius else Color(1, 0.5, 0, 0.15)
		var outline_color = Color(1, 0, 0, 0.3) if current_detection_radius == base_detection_radius else Color(1, 0.5, 0, 0.5)
		
		draw_circle(Vector2.ZERO, current_detection_radius, circle_color)  
		draw_arc(Vector2.ZERO, current_detection_radius, 0, TAU, 64, outline_color, 3.0)
	
	# Draw debug attack area (only when debug flag enabled)
	if debug_attack_range and attack_area:
		var attack_collision = attack_area.get_child(0) as CollisionShape2D
		if attack_collision and attack_collision.shape:
			var shape = attack_collision.shape as CircleShape2D
			if shape:
				var effective_radius = shape.radius * attack_collision.scale.x
				# Draw attack area in bright yellow during dash, blue when not dashing
				var attack_color = Color.YELLOW if is_dashing else Color.CYAN
				draw_circle(Vector2.ZERO, effective_radius, Color(attack_color.r, attack_color.g, attack_color.b, 0.3))
				draw_arc(Vector2.ZERO, effective_radius, 0, TAU, 32, attack_color, 2.0)

func debug_draw_attack_area():
	# Alternative method: Draw attack collision using Shape2D.draw()
	if debug_attack_range and is_dashing and attack_area:
		var attack_collision = attack_area.get_child(0) as CollisionShape2D
		if attack_collision and attack_collision.shape:
			# Get the actual collision shape and draw it
			var shape = attack_collision.shape as CircleShape2D
			if shape:
				# Draw with proper scale applied
				var actual_radius = shape.radius * attack_collision.scale.x  # 25.0 * 0.3 = 7.5px
				print("DEBUG: Attack area radius = ", actual_radius, "px")

func print_collision_debug():
	print("=== ENEMY COLLISION DEBUG ===")
	print("Enemy sprite scale: ", sprite.scale)
	print("Enemy sprite effective size: ", 64 * sprite.scale.x, "x", 64 * sprite.scale.y)
	
	# Enemy body collision
	var body_collision = get_node("CollisionShape2D") as CollisionShape2D
	if body_collision and body_collision.shape:
		var body_shape = body_collision.shape as RectangleShape2D
		if body_shape:
			print("Enemy body collision: ", body_shape.size, " at position ", body_collision.position)
	
	# Enemy attack area
	if attack_area:
		var attack_collision = attack_area.get_child(0) as CollisionShape2D
		if attack_collision and attack_collision.shape:
			var attack_shape = attack_collision.shape as CircleShape2D
			if attack_shape:
				var effective_radius = attack_shape.radius * attack_collision.scale.x
				print("Enemy attack collision: radius ", attack_shape.radius, " * scale ", attack_collision.scale.x, " = ", effective_radius, "px")
	
	# Player collision (for reference)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Player sprite scale: ", player.sprite.scale)
		print("Player sprite effective size: ", 64 * player.sprite.scale.x, "x", 64 * player.sprite.scale.y)
		var player_collision = player.get_node("CollisionShape2D") as CollisionShape2D
		if player_collision and player_collision.shape:
			var player_shape = player_collision.shape as RectangleShape2D
			if player_shape:
				print("Player body collision: ", player_shape.size)
	print("=== END COLLISION DEBUG ===")

func fix_collision_layers():
	# Ensure proper collision layer setup for Area2D detection
	print("=== FIXING COLLISION LAYERS ===")
	
	# Set enemy collision layer to 2, mask to 1 (to detect player)
	collision_layer = 2
	collision_mask = 1
	print("Enemy body - layer: ", collision_layer, " mask: ", collision_mask)
	
	# Set attack area mask to detect player on layer 1
	if attack_area:
		attack_area.collision_mask = 1  # Detect bodies on layer 1
		print("Enemy attack area - mask: ", attack_area.collision_mask)
	
	# Check player collision setup
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.collision_layer = 1  # Player on layer 1
		player.collision_mask = 2   # Player detects enemies on layer 2
		print("Player body - layer: ", player.collision_layer, " mask: ", player.collision_mask)
		
		# Set player attack area mask to detect enemies on layer 2
		var player_attack_area = player.get_node("AttackArea") as Area2D
		if player_attack_area:
			player_attack_area.collision_mask = 2  # Detect enemies on layer 2
			print("Player attack area - mask: ", player_attack_area.collision_mask)
	
	print("=== COLLISION LAYERS FIXED ===")

func fix_attack_area_size():
	# The enemy attack area scale is 0.3, making it only 7.5px radius - way too small!
	print("=== FIXING ATTACK AREA SIZE ===")
	
	if attack_area:
		var attack_collision = attack_area.get_child(0) as CollisionShape2D
		if attack_collision:
			# Change scale from 0.3 to 1.0 for reasonable attack range
			# This makes the radius 25px instead of 7.5px
			attack_collision.scale = Vector2(1.0, 1.0)
			print("Enemy attack area scale changed from 0.3 to 1.0")
			print("New effective radius: 25px (was 7.5px)")
			
			# Compare with player attack area
			var player = get_tree().get_first_node_in_group("player")
			if player:
				var player_attack_area = player.get_node("AttackArea") as Area2D
				if player_attack_area:
					var player_attack_collision = player_attack_area.get_child(0) as CollisionShape2D
					if player_attack_collision and player_attack_collision.shape:
						var player_shape = player_attack_collision.shape as CircleShape2D
						if player_shape:
							print("Player attack radius for comparison: ", player_shape.radius, "px")
	
	print("=== ATTACK AREA SIZE FIXED ===")

func enhance_detection_range():
	# Double the detection range when player is spotted
	current_detection_radius = enhanced_detection_radius
	# Vision system will use enhanced range automatically
	queue_redraw()
	print("Enemy enhanced detection - harder to escape!")

func reset_detection_range():
	# Return to normal detection range
	current_detection_radius = base_detection_radius
	# Vision system will use normal range automatically
	queue_redraw()

func can_see_player() -> bool:
	# Vision-based detection using raycasting and field of view
	# Get player reference if we don't have one
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
		if not player_ref:
			return false
	
	var to_player = player_ref.global_position - global_position
	var distance = to_player.length()
	
	# Check if player is within vision range (use enhanced range when applicable)
	var base_vision_range = enemy_data.vision_range if enemy_data else 200.0
	var effective_vision_range = base_vision_range
	
	# Use enhanced range if detection is currently enhanced
	if current_detection_radius > base_detection_radius:
		var enhancement_ratio = current_detection_radius / base_detection_radius
		effective_vision_range = base_vision_range * enhancement_ratio
	
	# Debug logging for problematic enemies
	var debug_enemy = enemy_data and enemy_data.enemy_name in ["Basic Balanced Enemy", "Stealth Paper Assassin"]
	
	if distance > effective_vision_range:
		if debug_enemy:
			print("VISION FAIL [%s]: Distance %.1f > Range %.1f" % [enemy_data.enemy_name, distance, effective_vision_range])
		return false
	
	# Check if player is within field of view
	var vision_angle = enemy_data.vision_angle if enemy_data else 60.0
	var angle_to_player = facing_direction.angle_to(to_player.normalized())
	var half_fov = deg_to_rad(vision_angle / 2.0)
	
	if abs(angle_to_player) > half_fov:
		if debug_enemy:
			print("VISION FAIL [%s]: Angle %.1f° > FOV %.1f°" % [enemy_data.enemy_name, rad_to_deg(abs(angle_to_player)), vision_angle/2])
		return false
	
	# Check line of sight with raycasting
	if vision_cast:
		vision_cast.target_position = to_player
		vision_cast.force_raycast_update()
		
		if vision_cast.is_colliding():
			var collider = vision_cast.get_collider()
			# If we hit something other than the player, vision is blocked
			if collider != player_ref:
				if debug_enemy:
					print("VISION FAIL [%s]: Raycast blocked by %s" % [enemy_data.enemy_name, collider.name if collider else "unknown"])
				return false
	
	if debug_enemy:
		print("VISION SUCCESS [%s]: Player detected!" % enemy_data.enemy_name)
	return true

func update_vision_detection():
	# Update vision-based player detection
	# Check for instant detection first
	if enemy_data and enemy_data.instant_detection:
		check_instant_detection()
		return
	
	# Use normal vision-based detection
	var player_visible = can_see_player()
	
	# Debug logging for vision detection
	if enemy_data and enemy_data.enemy_name in ["Basic Balanced Enemy", "Stealth Paper Assassin"]:
		var debug_state = "VISION DEBUG [%s]: Player visible = %s" % [enemy_data.enemy_name, player_visible]
		if player_ref:
			var distance = global_position.distance_to(player_ref.global_position)
			debug_state += ", Distance = %.1f" % distance
		print(debug_state)
	
	if player_visible:
		# Player is visible - enter detection state
		if not player_ref:
			player_ref = get_tree().get_first_node_in_group("player")
		
		if player_ref:
			# Handle detection logic (similar to old body_entered)
			_handle_player_detected()
	else:
		# Player not visible - handle loss of sight
		if player_ref:
			_handle_player_lost()

func check_instant_detection():
	# Instant detection system - detects player immediately within detection_radius
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
	
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		var detection_radius = enemy_data.detection_radius if enemy_data else 500.0
		
		# Debug logging for instant detection enemies
		var debug_enemy = enemy_data and enemy_data.enemy_name in ["Basic Balanced Enemy", "Scissor Scout Enemy", "Stealth Paper Assassin"]
		
		if distance_to_player <= detection_radius:
			# Player is within instant detection range
			# IMPORTANT: Respect IDLE state protection (same logic as vision system)
			if IdleState.can_be_detected_during_idle(self):
				if debug_enemy:
					# Debug: Instant detection successful
					pass
				_handle_player_detected()
			elif IdleState.is_idle_protected(self):
				# Debug: Instant detection blocked by idle protection
				print("DEBUG: Instant detection blocked - IDLE protected (", idle_timer, " seconds remaining)")
			elif debug_enemy:
				# Debug: Enemy busy during detection
				pass
		else:
			# Player is outside detection radius
			if debug_enemy:
				# Debug: Player out of detection range
				pass
			if player_ref:
				_handle_player_lost()

func _handle_player_detected():
	# Handle when player is detected via vision
	# Debug logging for Enemy 1
	if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
		print("_HANDLE_PLAYER_DETECTED [%s]: Current state = %s, instant_detection = %s" % [enemy_data.enemy_name, AIState.keys()[current_state], enemy_data.instant_detection])
	
	# Hide any active indicators when player is detected again
	if lost_indicator:
		lost_indicator.visible = false
	if alert_indicator and not is_alerting:
		alert_indicator.visible = false
	
	# Check if we were in patrol states (trigger alert)
	# IMPORTANT: Don't interrupt IDLE state until timer expires (protect 3-second idle animation)
	var was_patrolling = IdleState.was_patrolling(self)
	
	if was_patrolling:
		# Show alert first
		AlertState.start_alert_state(self, alert_duration)
		# Debug logging for Enemy 1
		if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
			print("AI STATE [%s]: %s → ALERT (alert_timer: %.1f)" % [enemy_data.enemy_name, "WALKING/IDLE", alert_timer])
	elif IdleState.is_idle_protected(self):
		# Debug: Player detected but idle state protected
		print("DEBUG: Player detected but IDLE state protected (", idle_timer, " seconds remaining)")
	else:
		# Debug logging for Enemy 1 - why not patrolling?
		if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
			print("_HANDLE_PLAYER_DETECTED [%s]: NOT patrolling! Current state = %s, was_patrolling = %s" % [enemy_data.enemy_name, AIState.keys()[current_state], was_patrolling])
		
		# Force into combat mode even if not patrolling (fix for stuck enemies)
		if current_state not in [AIState.ALERT, AIState.OBSERVING, AIState.POSITIONING, AIState.STANCE_SELECTION, AIState.ATTACKING]:
			AlertState.start_alert_state(self, alert_duration)
			if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
				print("AI STATE [%s]: FORCED → ALERT (fixing stuck state)" % [enemy_data.enemy_name])
		if alert_indicator:
			alert_indicator.visible = true
		# Enhance detection range when player is spotted
		enhance_detection_range()
		print("Enemy detected player - entering tactical mode")

func _handle_player_lost():
	# Handle when player is lost from vision
	# Don't interrupt if enemy is in attacking state (committed to attack)
	if current_state != AIState.ATTACKING:
		player_ref = null
		
		# Reset detection range when player escapes
		reset_detection_range()
		
		# Check if we were in combat states (not just walking around)
		var was_in_combat = current_state in [AIState.ALERT, AIState.OBSERVING, AIState.POSITIONING, AIState.STANCE_SELECTION, AIState.RETREATING]
		
		if was_in_combat:
			# Show confused/lost state
			current_state = AIState.LOST_PLAYER
			lost_player_timer = lost_player_duration
			if lost_indicator:
				lost_indicator.visible = true
			# print("Enemy lost sight of player")
		else:
			# Was just walking around, return to normal patrol
			current_state = AIState.WALKING
			# print("Enemy lost sight of player (returning to patrol)")

# update_enemy_dash_preview() function removed for complete overhaul

func add_immunity_visual_feedback():
	# Create flickering effect during immunity frames
	if is_immune:
		var flicker_tween = create_tween()
		flicker_tween.set_loops(int(immunity_duration * 10))  # Flicker 10 times per second
		flicker_tween.tween_property(sprite, "modulate:a", 0.3, 0.05)
		flicker_tween.tween_property(sprite, "modulate:a", 1.0, 0.05)

func is_currently_dashing() -> bool:
	return is_dashing

func detect_mutual_attack_with_player() -> bool:
	# Check if player is also dashing (mutual attack scenario)
	if player_ref and player_ref.has_method("is_currently_dashing"):
		return player_ref.is_currently_dashing()
	return false

func detect_mutual_attack_with_body(body) -> bool:
	# Check if the given body (player) is also dashing (mutual attack scenario)
	if body and body.has_method("is_currently_dashing"):
		return body.is_currently_dashing()
	return false

func _on_attack_area_body_entered(body):
	# Attack area entry is now handled in the tactical AI states
	pass
