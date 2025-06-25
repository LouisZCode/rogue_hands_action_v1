extends CharacterBody2D
class_name Enemy

# === ENEMY DATA RESOURCE ===
@export var enemy_data: EnemyData
var default_data: EnemyData  # Fallback if no resource assigned

# AI and movement variables (loaded from resource)
var speed: float = 100.0
var detection_range: float = 150.0
var attack_range: float = 100.0
var dash_speed: float = 300.0
var dash_duration: float = 0.6

# Debug/Testing variables
@export var debug_rock_only: bool = false  # Use CSV-based stance probabilities

# Combat variables  
enum Stance { NEUTRAL, ROCK, PAPER, SCISSORS }
var current_stance: Stance = Stance.NEUTRAL  # Start in neutral like player
var max_health: int = 5
var current_health: int = 5

# Defense point system
var max_defense_points: int = 1
var current_defense_points: int = 1

# AI State - Enhanced tactical system
enum AIState { IDLE, WALKING, LOST_PLAYER, ALERT, OBSERVING, POSITIONING, STANCE_SELECTION, ATTACKING, RETREATING, STUNNED }
var current_state: AIState = AIState.WALKING
var player_ref: Player = null

# Attack system mirroring player
var attack_cooldown: float = 1.2  # Slightly longer than player
var attack_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0

# Tactical AI variables
var stance_decision_timer: float = 0.0
var positioning_timer: float = 0.0
var retreat_timer: float = 0.0
var last_player_stance: Player.Stance = Player.Stance.NEUTRAL
var stance_change_cooldown: float = 0.5
var stance_change_timer: float = 0.0
var stance_to_dash_delay: float = 1.0  # 1 second delay after stance change (reduced for testing)
var stance_to_dash_timer: float = 0.0
var target_attack_position: Vector2  # Store player position when stance is selected

# Walking state variables
var walking_direction: Vector2 = Vector2.ZERO
var walking_timer: float = 0.0
var walking_speed: float = 50.0  # Slower than normal speed
var direction_change_interval: float = 2.5  # Change direction every 2.5 seconds

# Idle and lost player state variables
var idle_timer: float = 0.0
var idle_duration_min: float = 1.0
var idle_duration_max: float = 3.0
var lost_player_timer: float = 0.0
var lost_player_duration: float = 2.5  # Time spent confused before giving up

# Alert state variables
var alert_timer: float = 0.0
var alert_duration: float = 1.0  # 1 second alert display
var is_alerting: bool = false

# Immunity frames to prevent multiple hits
@export var immunity_duration: float = 0.5
var immunity_timer: float = 0.0
var is_immune: bool = false

# Stun system (enhanced existing STUNNED state)
@export var stun_duration: float = 3.0
var stun_timer: float = 0.0

# Track which players have been hit during current dash
var players_hit_this_dash: Array[Node] = []

# References
@onready var sprite: AnimatedSprite2D = $Sprite
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
@onready var dash_preview: DashPreview = $DashPreview

# Audio management
var audio_manager: AudioManager

# Debug visualization
var debug_detection_range: bool = false  # Detection range circles disabled
var debug_attack_range: bool = false  # Attack collision circles disabled
var base_detection_radius: float = 150.0  # Normal detection range
var enhanced_detection_radius: float = 300.0  # When player is spotted (double size)
var current_detection_radius: float = 150.0  # Current radius for drawing

# Vision system
var facing_direction: Vector2 = Vector2(1, 0)  # Default facing right
var last_player_position: Vector2 = Vector2.ZERO
var vision_timer: float = 0.0
var vision_check_interval: float = 0.1  # Check vision 10 times per second

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
	"""Load variables from EnemyData resource or create default values"""
	
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
	"""Create default EnemyData if none assigned"""
	var data = EnemyData.new()
	data.enemy_name = "Default Enemy"
	# All other values will use the defaults from EnemyData.gd
	return data

func apply_collision_settings():
	"""Apply collision settings from enemy data to the actual collision shapes"""
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
	"""Apply visual customization from enemy data with animations"""
	if not enemy_data:
		return
	
	# Get animated sprite node
	var sprite_node = get_node("Sprite") as AnimatedSprite2D
	if not sprite_node:
		print("ERROR: No AnimatedSprite2D node found for visual data application")
		return
	
	# Create SpriteFrames resource with animations
	setup_enemy_animations(sprite_node)
	
	# Apply scale
	sprite_node.scale = enemy_data.sprite_scale
	
	# Start with idle animation
	sprite_node.play("idle")
	
	# Apply color tint
	sprite_node.modulate = enemy_data.color_tint
	
	print("Applied visual data - Scale: ", enemy_data.sprite_scale, " Tint: ", enemy_data.color_tint)

func setup_enemy_animations(sprite_node: AnimatedSprite2D):
	"""Create SpriteFrames resource with idle, walk, and walk_eye animations"""
	var sprite_frames = SpriteFrames.new()
	
	# Load the three animation spritesheets
	var idle_texture = preload("res://assets/assets_game/enemy_idle.png")
	var walk_texture = preload("res://assets/assets_game/enemy_walk.png")
	var walk_eye_texture = preload("res://assets/assets_game/enemy_walking_eye.png")
	
	# Add animations to SpriteFrames
	add_spritesheet_frames(sprite_frames, "idle", idle_texture, 64, 64)
	add_spritesheet_frames(sprite_frames, "walk", walk_texture, 64, 64)
	add_spritesheet_frames(sprite_frames, "walk_eye", walk_eye_texture, 64, 64)
	
	# Apply the SpriteFrames to the AnimatedSprite2D
	sprite_node.sprite_frames = sprite_frames
	
	print("Enemy animations setup complete: idle, walk, walk_eye")

func add_spritesheet_frames(sprite_frames: SpriteFrames, animation_name: String, texture: Texture2D, frame_width: int, frame_height: int):
	"""Extract frames from a spritesheet and add them to SpriteFrames"""
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
	
	print("Added ", frames_x * frames_y, " frames for animation: ", animation_name)

func apply_enemy_data():
	"""Apply enemy data to all relevant systems"""
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
	
	# Apply collision settings
	apply_collision_settings()
	
	# Apply visual settings
	apply_visual_data()
	
	# Emit defense points changed signal
	enemy_defense_points_changed.emit(current_defense_points, max_defense_points)
	
	print("Applied enemy data: ", enemy_data.enemy_name, " (", enemy_data.get_archetype_description(), ")")


func _ready():
	# Initialize audio manager
	audio_manager = AudioManager.new()
	
	# Load enemy data from resource
	if enemy_data:
		print("Enemy_data found: ", enemy_data.enemy_name)
		apply_enemy_data()
	else:
		print("No enemy_data found, loading defaults...")
		load_enemy_data()
	
	# Initialize dash preview for enemy
	if dash_preview:
		dash_preview.set_enemy_style()
	
	update_visual()
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
	pick_new_walking_direction()
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
	# DEBUG: Show dash state
	if is_dashing:
		print("DEBUG _physics_process: Enemy is dashing - position: ", global_position, " dash_timer: ", dash_timer)
	
	# Update vision detection system
	vision_timer += delta
	if vision_timer >= vision_check_interval:
		vision_timer = 0.0
		update_vision_detection()
	
	update_ai(delta)
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
			velocity = Vector2.ZERO
			current_stance = Stance.NEUTRAL
			# Hide any lingering indicators
			hide_all_indicators()
			# Check if idle time is over
			if idle_timer <= 0:
				current_state = AIState.WALKING
				pick_new_walking_direction()
				walking_timer = direction_change_interval
		
		AIState.WALKING:
			# Random walking behavior when no player detected
			current_stance = Stance.NEUTRAL
			# Hide any lingering indicators
			hide_all_indicators()
			handle_walking_movement()
		
		AIState.LOST_PLAYER:
			# Stand still and look confused
			velocity = Vector2.ZERO
			current_stance = Stance.NEUTRAL
			# Check if confusion time is over
			if lost_player_timer <= 0:
				# Hide lost indicator
				if lost_indicator:
					lost_indicator.visible = false
					# print("DEBUG: Hiding lost indicator - timer expired")
				# Reset detection range when giving up search
				reset_detection_range()
				# Return to walking
				current_state = AIState.WALKING
				pick_new_walking_direction()
				walking_timer = direction_change_interval
				# print("DEBUG: Lost player timer expired, returning to walking")
		
		AIState.ALERT:
			# Stand still and show alert - brief pause before engaging
			velocity = Vector2.ZERO
			current_stance = Stance.NEUTRAL
			# Check if alert time is over
			if alert_timer <= 0:
				# Hide alert indicator
				if alert_indicator:
					alert_indicator.visible = false
				is_alerting = false
				# Start observing player
				current_state = AIState.OBSERVING
				positioning_timer = randf_range(0.01, 0.05)  # Near-instant reaction
				# Debug logging for Enemy 1
				if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
					print("AI STATE [%s]: ALERT → OBSERVING (timer: %.3f)" % [enemy_data.enemy_name, positioning_timer])
			
		AIState.OBSERVING:
			# Stand still and observe player behavior
			velocity = Vector2.ZERO
			observe_player()
			
			# After observing, decide on positioning
			if positioning_timer <= 0:
				current_state = AIState.POSITIONING
				positioning_timer = randf_range(0.1, 0.3)  # Quick positioning
				# Debug logging for Enemy 1
				if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
					print("AI STATE [%s]: OBSERVING → POSITIONING (timer: %.3f)" % [enemy_data.enemy_name, positioning_timer])
			
		AIState.POSITIONING:
			# Move to tactical position while staying in neutral
			if player_ref:
				position_tactically()
				
				# If close enough and ready to attack, select stance
				var distance = global_position.distance_to(player_ref.global_position)
				if distance <= attack_range * 1.5 and attack_timer <= 0:
					current_state = AIState.STANCE_SELECTION
					stance_decision_timer = 0.3  # Time to decide stance
					# Debug logging for Enemy 1
					if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
						print("AI STATE [%s]: POSITIONING → STANCE_SELECTION (distance: %.1f, attack_range: %.1f, attack_timer: %.1f)" % [enemy_data.enemy_name, distance, attack_range, attack_timer])
				elif enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
					print("AI STATE [%s]: POSITIONING waiting (distance: %.1f > %.1f OR attack_timer: %.1f > 0)" % [enemy_data.enemy_name, distance, attack_range * 1.5, attack_timer])
			
		AIState.STANCE_SELECTION:
			# Stop moving and select counter-stance
			velocity = Vector2.ZERO
			if stance_decision_timer <= 0:
				select_tactical_stance()
				# Start the 2-second delay before dash attack
				stance_to_dash_timer = stance_to_dash_delay
				current_state = AIState.ATTACKING
				# Debug logging for Enemy 1
				if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
					print("AI STATE [%s]: STANCE_SELECTION → ATTACKING (stance: %s, dash_delay: %.1f)" % [enemy_data.enemy_name, Stance.keys()[current_stance], stance_to_dash_timer])
			
		AIState.ATTACKING:
			# Show dash trajectory to target position
			update_enemy_dash_preview()
			# Once in attacking state, commit to the attack regardless of player position
			if current_stance != Stance.NEUTRAL:
				# Only attack after 2-second delay and cooldown is ready
				if attack_timer <= 0 and stance_to_dash_timer <= 0:
					perform_dash_attack()
			else:
				current_state = AIState.RETREATING
				retreat_timer = 1.0
				# Hide attack timer when exiting attacking state
				if attack_timer_bar:
					attack_timer_bar.visible = false
				# Hide dash preview when exiting attacking state
				if dash_preview:
					dash_preview.hide_dash_trajectory()
				
		AIState.RETREATING:
			# Hide dash preview when retreating
			if dash_preview:
				dash_preview.hide_dash_trajectory()
			# Move away and return to neutral
			if player_ref:
				retreat_from_player()
				
			if retreat_timer <= 0:
				current_stance = Stance.NEUTRAL
				update_visual()
				# Return to walking if no player, otherwise keep observing
				if player_ref:
					current_state = AIState.OBSERVING
					positioning_timer = randf_range(0.5, 1.5)
				else:
					# Show confusion after retreat before going back to patrol
					current_state = AIState.LOST_PLAYER
					lost_player_timer = lost_player_duration
					if lost_indicator:
						lost_indicator.visible = true
					print("DEBUG: Retreat finished, showing confusion, timer set to: ", lost_player_timer)
				
		AIState.STUNNED:
			velocity = Vector2.ZERO
			# Check if stun timer is done
			if stun_timer <= 0:
				current_state = AIState.RETREATING
				retreat_timer = 1.0
				# Hide stun indicator when stun ends
				if stun_indicator:
					stun_indicator.visible = false
	
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
					# print("DEBUG: Enemy colliding with player - Enemy pos: ", global_position, " Player pos: ", player.global_position, " Distance: ", distance)
					
					# Apply separation force if too close and not dashing
					if distance < 30.0 and not is_dashing and not player.is_currently_dashing():
						var separation_direction = (global_position - player.global_position).normalized()
						var separation_force = separation_direction * 40.0  # Push away gently
						velocity += separation_force
						# print("DEBUG: Applying separation force to enemy: ", separation_force)

func handle_walking_movement():
	# Change direction periodically or if hitting boundaries
	if walking_timer <= 0 or is_near_boundary():
		# 40% chance to go idle instead of continuing to walk
		if randf() < 0.4:
			current_state = AIState.IDLE
			idle_timer = randf_range(idle_duration_min, idle_duration_max)
			velocity = Vector2.ZERO
			return
		else:
			pick_new_walking_direction()
			walking_timer = direction_change_interval + randf_range(-0.5, 0.5)  # Add some randomness
	
	# Move in the current walking direction
	velocity = walking_direction * walking_speed
	# Update facing direction based on movement
	if walking_direction.length() > 0.1:
		facing_direction = walking_direction.normalized()

func pick_new_walking_direction():
	# Pick a random direction
	var angle = randf() * 2 * PI
	walking_direction = Vector2(cos(angle), sin(angle))
	# Update facing direction immediately
	facing_direction = walking_direction.normalized()
	
	# Make sure we're not walking directly into a wall
	var test_position = global_position + walking_direction * 100
	if is_position_near_boundary(test_position):
		# Pick direction towards center instead
		walking_direction = (Vector2.ZERO - global_position).normalized()
		# Add some randomness to avoid getting stuck
		var random_offset = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		walking_direction = (walking_direction + random_offset).normalized()

func is_near_boundary() -> bool:
	return is_position_near_boundary(global_position)

func is_position_near_boundary(pos: Vector2) -> bool:
	# Check if position is near arena boundaries (with some margin)
	var margin = 50.0
	return pos.x < -425 + margin or pos.x > 425 - margin or pos.y < -275 + margin or pos.y > 275 - margin

# New AI methods for tactical combat
func observe_player():
	if player_ref:
		# Track player's stance changes
		if player_ref.current_stance != last_player_stance:
			last_player_stance = player_ref.current_stance
			print("Enemy observed player change to: ", Player.Stance.keys()[last_player_stance])

func position_tactically():
	if player_ref:
		# Only move if in neutral stance (like player)
		if current_stance != Stance.NEUTRAL:
			velocity = Vector2.ZERO
			return
			
		var distance = global_position.distance_to(player_ref.global_position)
		var direction = (player_ref.global_position - global_position).normalized()
		
		# Try to maintain optimal distance - close enough to attack, far enough to retreat
		if distance > attack_range * 1.2:
			# Move closer
			velocity = direction * speed
		elif distance < attack_range * 0.8:
			# Move away to optimal distance
			velocity = -direction * speed * 0.7
		else:
			# Circle around player to find good attack angle
			var perpendicular = Vector2(-direction.y, direction.x)
			velocity = perpendicular * speed * 0.5

func select_tactical_stance():
	if player_ref:
		var player_stance = player_ref.current_stance
		
		# Store the player's position at the moment of stance selection
		target_attack_position = player_ref.global_position
		
		print("ENEMY: Stance selection - Enemy position: ", global_position, " - Target position: ", target_attack_position)
		
		# Debug mode: Always use Rock for testing
		if debug_rock_only:
			current_stance = Stance.ROCK
			update_visual()
			print("ENEMY: Selected ROCK (debug mode) vs player's ", Player.Stance.keys()[player_stance])
			print("ENEMY: Attack trajectory from ", global_position, " to ", target_attack_position)
			return
		
		# Stance selection based on CSV probabilities
		current_stance = select_weighted_stance()
		
		update_visual()
		print("Enemy selected ", Stance.keys()[current_stance], " to counter player's ", Player.Stance.keys()[player_stance])
		print("Target locked at position: ", target_attack_position)

func chase_player():
	if player_ref:
		# Only move if in neutral stance (like player)
		if current_stance != Stance.NEUTRAL:
			velocity = Vector2.ZERO
			return
			
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * speed

func retreat_from_player():
	if player_ref:
		# Only move if in neutral stance (like player)
		if current_stance != Stance.NEUTRAL:
			velocity = Vector2.ZERO
			return
			
		var direction = (global_position - player_ref.global_position).normalized()
		velocity = direction * speed * 0.8

func handle_dash_movement(delta):
	# No dash movement allowed when stunned
	if current_state == AIState.STUNNED:
		if is_dashing:
			# Cancel ongoing dash when stunned
			is_dashing = false
			dash_timer = 0.0
			velocity = Vector2.ZERO
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
			retreat_timer = 1.0
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
					# print("DEBUG: Enemy DASH colliding with player - Enemy pos: ", global_position, " Player pos: ", collision.get_collider().global_position, " Distance: ", global_position.distance_to(collision.get_collider().global_position))
					pass
			
		# Check for player hits during dash
		# print("DEBUG: Calling attack_during_dash() - Enemy at: ", global_position)
		attack_during_dash()

func perform_dash_attack():
	if current_stance != Stance.NEUTRAL:
		# Calculate attack direction using stored target position
		var direction = (target_attack_position - global_position).normalized()
		
		# Start dash attack
		is_dashing = true
		dash_direction = direction
		dash_timer = dash_duration
		attack_timer = attack_cooldown
		
		# Clear the list of players hit this dash
		players_hit_this_dash.clear()
		
		# Visual feedback
		var dash_color = stance_colors[current_stance].lerp(Color.WHITE, 0.5)
		sprite.modulate = dash_color
		
		# DEBUG: Make enemy glow bright red during attack for visibility
		if debug_attack_range:
			sprite.modulate = Color.RED
			debug_draw_attack_area()
			queue_redraw()
		
		# Reset color after dash
		var tween = create_tween()
		tween.tween_interval(dash_duration)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
		# Emit attack signal
		enemy_attack.emit(current_stance, global_position)
		print("Enemy dash attacks with: ", Stance.keys()[current_stance], " towards stored target position")

func attack_during_dash():
	# DEBUG: Add comprehensive logging
	# print("=== ENEMY ATTACK_DURING_DASH DEBUG ===")
	# print("Enemy position: ", global_position)
	# print("Enemy is_dashing: ", is_dashing)
	# print("Enemy current_stance: ", Stance.keys()[current_stance])
	
	# Check for player hits using the actual attack area collision
	var bodies = attack_area.get_overlapping_bodies()
	# print("Bodies found in attack_area: ", bodies.size())
	
	if bodies.size() == 0:
		# print("DEBUG: NO BODIES FOUND - Attack area empty!")
		# Additional debug: Check if attack_area exists and is configured
		if not attack_area:
			# print("ERROR: attack_area is null!")
			pass
		else:
			# print("Attack area exists, checking collision shape...")
			var attack_collision = attack_area.get_child(0) as CollisionShape2D
			if not attack_collision:
				# print("ERROR: No collision shape found in attack_area!")
				pass
			elif not attack_collision.shape:
				# print("ERROR: Collision shape is null!")
				pass
			else:
				var shape = attack_collision.shape as CircleShape2D
				if shape:
					var effective_radius = shape.radius * attack_collision.scale.x
					# print("Attack collision shape radius: ", shape.radius)
					# print("Attack collision scale: ", attack_collision.scale)
					# print("Effective attack radius: ", effective_radius, "px")
					# print("Attack collision position: ", attack_collision.global_position)
					pass
				else:
					# print("ERROR: Shape is not CircleShape2D!")
					pass
	else:
		# print("Bodies found:")
		for i in range(bodies.size()):
			var body = bodies[i]
			# print("  [", i, "] ", body.name, " (", body.get_class(), ") at ", body.global_position)
			# print("      Distance to enemy: ", global_position.distance_to(body.global_position))
			pass
	
	# Check if player exists in scene
	var player_ref = get_tree().get_first_node_in_group("player")
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		print("Player found in scene at: ", player_ref.global_position)
		print("Distance to player: ", distance_to_player, "px")
		print("Player collision layers: ", player_ref.collision_layer)
		print("Player collision mask: ", player_ref.collision_mask)
		print("Enemy collision layers: ", collision_layer)
		print("Enemy collision mask: ", collision_mask)
		print("Attack area collision layers: ", attack_area.collision_layer)
		print("Attack area collision mask: ", attack_area.collision_mask)
	else:
		print("ERROR: No player found in scene!")
	
	print("Players already hit this dash: ", players_hit_this_dash.size())
	print("=== END DEBUG ===")
	
	for body in bodies:
		if body is Player and not body in players_hit_this_dash:
			# Detect combat scenario: mutual attack or attack vs defense
			var is_mutual_attack = detect_mutual_attack_with_body(body)
			# Calculate combat result based on stance matchup and scenario
			var combat_result = calculate_combat_damage(current_stance, body.current_stance, is_mutual_attack)
			
			# Handle defense point consumption
			if combat_result.player_defense_consumed:
				if body.has_method("consume_defense_point"):
					if body.consume_defense_point():
						print("Player blocked with defense point!")
						# Play regular block sound (successful block outside parry window)
						if body.audio_manager and body.walking_audio:
							body.audio_manager.play_regular_block_sfx(body.walking_audio)
					else:
						# No defense points left, take damage instead (reduced for same-stance balance)
						combat_result.damage = 1
						body.take_damage(combat_result.damage)
				else:
					# Fallback if method doesn't exist
					body.take_damage(combat_result.damage)
			elif combat_result.damage > 0:
				# V2: Handle weak stance damage absorption
				if combat_result.weak_stance_damage and body.has_method("consume_multiple_defense_points"):
					# Try to absorb weak stance damage with defense points
					var absorbed_damage = body.consume_multiple_defense_points(combat_result.damage)
					var remaining_damage = combat_result.damage - absorbed_damage
					if absorbed_damage > 0:
						print("Defense points absorbed ", absorbed_damage, " damage from weak stance!")
					if remaining_damage > 0:
						body.take_damage(remaining_damage)
				else:
					# Regular damage application
					body.take_damage(combat_result.damage)
			
			# Handle enemy stun (parry success!)
			if combat_result.enemy_stunned:
				apply_stun()
			
			# Add player to the list of already hit players
			players_hit_this_dash.append(body)
			print("Enemy attack result: ", combat_result.damage, " damage (mutual: ", is_mutual_attack, ")")

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
	# Returns: {damage: int, enemy_stunned: bool, player_defense_consumed: bool, weak_stance_damage: bool}
	var result = {"damage": 0, "enemy_stunned": false, "player_defense_consumed": false, "weak_stance_damage": false}
	
	var player_stance_int = int(player_stance)
	var enemy_stance_int = int(enemy_stance)
	
	# Mutual attack scenario (both dashing)
	if is_mutual_attack:
		if enemy_stance_int == player_stance_int:
			# Tie - no damage to either
			result.damage = 0
			return result
		elif (enemy_stance_int == 1 and player_stance_int == 3) or \
			 (enemy_stance_int == 2 and player_stance_int == 1) or \
			 (enemy_stance_int == 3 and player_stance_int == 2):
			# Enemy wins - player gets stunned, enemy deals 2 damage
			result.damage = 2
			return result
		else:
			# Enemy loses - enemy gets stunned, no damage
			result.damage = 0
			result.enemy_stunned = true
			return result
	
	# Attack vs Defense scenario (enemy attacking, player defending)
	if player_stance_int == 0:  # vs Neutral
		result.damage = 1
	elif enemy_stance_int == player_stance_int:  # Same stance defense
		result.damage = 0
		result.player_defense_consumed = true
	elif (enemy_stance_int == 1 and player_stance_int == 3) or \
		 (enemy_stance_int == 2 and player_stance_int == 1) or \
		 (enemy_stance_int == 3 and player_stance_int == 2):
		# Enemy wins - V2: Defense points can absorb weak stance damage
		result.damage = 2
		result.weak_stance_damage = true  # Mark this as weak stance damage for special handling
	else:
		# Enemy loses - check if player is in parry window for perfect parry
		result.damage = 0
		# Check if player has parry window active for perfect parry
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
	var player_stance_int = int(player_stance)
	var enemy_stance_int = int(current_stance)
	
	var damage = 0
	var result = ""
	var player_stunned = false
	var enemy_defense_consumed = false
	
	# Mutual attack scenario (both dashing)
	if is_mutual_attack:
		if player_stance_int == enemy_stance_int:
			# Tie - no damage to either
			damage = 0
			result = "MUTUAL TIE - No damage"
		elif (player_stance_int == 1 and enemy_stance_int == 3) or \
			 (player_stance_int == 2 and enemy_stance_int == 1) or \
			 (player_stance_int == 3 and enemy_stance_int == 2):
			# Player wins - enemy takes 2 damage
			damage = 2
			result = "MUTUAL WIN - Player " + Player.Stance.keys()[player_stance] + " beats " + Stance.keys()[current_stance]
		else:
			# Player loses - player gets stunned, no damage to enemy
			damage = 0
			player_stunned = true
			result = "MUTUAL LOSS - Player stunned by " + Stance.keys()[current_stance]
	else:
		# Attack vs Defense scenario (player attacking, enemy defending)
		if enemy_stance_int == 0:  # Enemy in neutral
			damage = 1
			result = "vs NEUTRAL - 1 damage"
		elif player_stance_int == enemy_stance_int:  # Same stance defense
			damage = 0
			enemy_defense_consumed = true
			result = "BLOCKED - Enemy used defense point"
		elif (player_stance_int == 1 and enemy_stance_int == 3) or \
			 (player_stance_int == 2 and enemy_stance_int == 1) or \
			 (player_stance_int == 3 and enemy_stance_int == 2):
			# Player wins
			damage = 2
			result = "PLAYER WINS - " + Player.Stance.keys()[player_stance] + " beats " + Stance.keys()[current_stance]
		else:
			# Player loses (parry) - player gets stunned
			damage = 0
			player_stunned = true
			result = "PARRY - Player stunned by " + Stance.keys()[current_stance]
	
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
		if player_ref and player_ref.has_method("apply_stun"):
			player_ref.apply_stun()
	
	print("Combat: Player ", Player.Stance.keys()[player_stance], " vs Enemy ", Stance.keys()[current_stance], " - Damage: ", damage, " - ", result)

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
		stun_timer.tween_callback(func(): 
			current_state = AIState.RETREATING
			retreat_timer = 1.0
		).set_delay(0.5)

func update_timers(delta):
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
			#print("DEBUG: Lost player timer: ", lost_player_timer)
	
	# Update alert timer
	if alert_timer > 0:
		alert_timer -= delta

func update_visual():
	# Update animation based on AI state and movement
	if sprite and sprite.sprite_frames:
		match current_state:
			AIState.IDLE, AIState.STUNNED, AIState.POSITIONING, AIState.STANCE_SELECTION:
				if sprite.animation != "idle":
					sprite.play("idle")
			AIState.WALKING, AIState.LOST_PLAYER, AIState.RETREATING:
				if sprite.animation != "walk":
					sprite.play("walk")
			AIState.ALERT, AIState.OBSERVING:
				if sprite.animation != "walk_eye":
					sprite.play("walk_eye")
			AIState.ATTACKING:
				# Keep current animation during attack
				pass
	
	# stance_label.text = stance_symbols[current_stance]  # Disabled stance emoji display
	update_health_bar()
	update_defense_point_visual()

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
	"""Vision-based detection using raycasting and field of view"""
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
	"""Update vision-based player detection"""
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
	"""Instant detection system - detects player immediately within detection_radius"""
	if not player_ref:
		player_ref = get_tree().get_first_node_in_group("player")
	
	if player_ref:
		var distance_to_player = global_position.distance_to(player_ref.global_position)
		var detection_radius = enemy_data.detection_radius if enemy_data else 500.0
		
		# Debug logging for instant detection enemies
		var debug_enemy = enemy_data and enemy_data.enemy_name in ["Basic Balanced Enemy", "Scissor Scout Enemy", "Stealth Paper Assassin"]
		
		if distance_to_player <= detection_radius:
			# Player is within instant detection range
			if current_state in [AIState.IDLE, AIState.WALKING]:
				if debug_enemy:
					print("INSTANT DETECTION [%s]: Player detected at distance %.1f (max: %.1f)" % [enemy_data.enemy_name, distance_to_player, detection_radius])
				_handle_player_detected()
			elif debug_enemy:
				print("INSTANT DETECTION [%s]: Player in range but enemy busy (state: %s)" % [enemy_data.enemy_name, AIState.keys()[current_state]])
		else:
			# Player is outside detection radius
			if debug_enemy:
				print("INSTANT DETECTION [%s]: Player too far %.1f > %.1f" % [enemy_data.enemy_name, distance_to_player, detection_radius])
			if player_ref:
				_handle_player_lost()

func _handle_player_detected():
	"""Handle when player is detected via vision"""
	# Debug logging for Enemy 1
	if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
		print("_HANDLE_PLAYER_DETECTED [%s]: Current state = %s, instant_detection = %s" % [enemy_data.enemy_name, AIState.keys()[current_state], enemy_data.instant_detection])
	
	# Hide any active indicators when player is detected again
	if lost_indicator:
		lost_indicator.visible = false
	if alert_indicator and not is_alerting:
		alert_indicator.visible = false
	
	# Check if we were in patrol states (trigger alert)
	var was_patrolling = current_state in [AIState.WALKING, AIState.IDLE]
	
	if was_patrolling:
		# Show alert first
		current_state = AIState.ALERT
		is_alerting = true
		alert_timer = alert_duration
		# Debug logging for Enemy 1
		if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
			print("AI STATE [%s]: %s → ALERT (alert_timer: %.1f)" % [enemy_data.enemy_name, "WALKING/IDLE", alert_timer])
	else:
		# Debug logging for Enemy 1 - why not patrolling?
		if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
			print("_HANDLE_PLAYER_DETECTED [%s]: NOT patrolling! Current state = %s, was_patrolling = %s" % [enemy_data.enemy_name, AIState.keys()[current_state], was_patrolling])
		
		# Force into combat mode even if not patrolling (fix for stuck enemies)
		if current_state not in [AIState.ALERT, AIState.OBSERVING, AIState.POSITIONING, AIState.STANCE_SELECTION, AIState.ATTACKING]:
			current_state = AIState.ALERT
			is_alerting = true
			alert_timer = alert_duration
			if enemy_data and enemy_data.enemy_name == "Basic Balanced Enemy":
				print("AI STATE [%s]: FORCED → ALERT (fixing stuck state)" % [enemy_data.enemy_name])
		if alert_indicator:
			alert_indicator.visible = true
		# Enhance detection range when player is spotted
		enhance_detection_range()
		print("Enemy detected player - entering tactical mode")

func _handle_player_lost():
	"""Handle when player is lost from vision"""
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

func update_enemy_dash_preview():
	# Show simple trajectory line from enemy position to target when attacking
	if not dash_preview:
		return
		
	# Show trajectory only in ATTACKING state with a stance selected
	if current_state == AIState.ATTACKING and current_stance != Stance.NEUTRAL and player_ref:
		# Calculate direction to target and apply consistent dash distance
		var direction_to_target = (target_attack_position - global_position).normalized()
		var enemy_dash_distance = dash_speed * dash_duration  # 300 * 0.6 = 180 pixels
		var relative_target = direction_to_target * enemy_dash_distance
		dash_preview.show_simple_dash_line(relative_target)
		# Debug: Show exact positions
		if stance_to_dash_timer > stance_to_dash_delay * 0.8:  # Only print early in attack phase
			print("ENEMY: Dash line relative vector: ", relative_target, " (consistent distance: ", enemy_dash_distance, "px)")
	else:
		# Hide trajectory if not in attacking state
		dash_preview.hide_dash_trajectory()

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

func select_weighted_stance() -> Stance:
	"""Select stance based on CSV probability weights"""
	if not enemy_data:
		# Fallback to random if no data
		var stances = [Stance.NEUTRAL, Stance.ROCK, Stance.PAPER, Stance.SCISSORS]
		return stances[randi() % stances.size()]
	
	# Get probabilities from enemy data
	var total_weight = enemy_data.neutral_probability + enemy_data.rock_probability + enemy_data.paper_probability + enemy_data.scissors_probability
	
	if total_weight <= 0:
		# Fallback to balanced if all weights are 0
		return Stance.ROCK
	
	# Generate random number between 0 and total weight
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	# Check neutral stance
	cumulative_weight += enemy_data.neutral_probability
	if random_value <= cumulative_weight:
		return Stance.NEUTRAL
	
	# Check rock stance
	cumulative_weight += enemy_data.rock_probability
	if random_value <= cumulative_weight:
		return Stance.ROCK
	
	# Check paper stance
	cumulative_weight += enemy_data.paper_probability
	if random_value <= cumulative_weight:
		return Stance.PAPER
	
	# Default to scissors (or if rounding errors)
	return Stance.SCISSORS
