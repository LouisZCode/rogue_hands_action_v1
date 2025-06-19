extends CharacterBody2D
class_name Enemy

# AI and movement variables
@export var speed: float = 100.0
@export var detection_range: float = 150.0
@export var attack_range: float = 50.0
@export var dash_speed: float = 300.0  # Half of player dash speed
@export var dash_duration: float = 0.3

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
var stance_to_dash_delay: float = 2.0  # 2 second delay after stance change
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
@onready var sprite: Sprite2D = $Sprite
@onready var stance_label: Label = $StanceLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var defense_point_label: Label = $DefensePoint
@onready var stun_indicator: Label = $StunIndicator
@onready var lost_indicator: Label = $LostIndicator
@onready var alert_indicator: Label = $AlertIndicator
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

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

func _ready():
	update_visual()
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	# Emit initial defense points
	enemy_defense_points_changed.emit(current_defense_points, max_defense_points)
	
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
	
func _physics_process(delta):
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
					print("DEBUG: Hiding lost indicator - timer expired")
				# Return to walking
				current_state = AIState.WALKING
				pick_new_walking_direction()
				walking_timer = direction_change_interval
				print("DEBUG: Lost player timer expired, returning to walking")
		
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
				positioning_timer = randf_range(0.5, 1.0)
			
		AIState.OBSERVING:
			# Stand still and observe player behavior
			velocity = Vector2.ZERO
			observe_player()
			
			# After observing, decide on positioning
			if positioning_timer <= 0:
				current_state = AIState.POSITIONING
				positioning_timer = randf_range(1.0, 2.0)
			
		AIState.POSITIONING:
			# Move to tactical position while staying in neutral
			if player_ref:
				position_tactically()
				
				# If close enough and ready to attack, select stance
				var distance = global_position.distance_to(player_ref.global_position)
				if distance <= attack_range * 1.5 and attack_timer <= 0:
					current_state = AIState.STANCE_SELECTION
					stance_decision_timer = 0.3  # Time to decide stance
			
		AIState.STANCE_SELECTION:
			# Stop moving and select counter-stance
			velocity = Vector2.ZERO
			if stance_decision_timer <= 0:
				select_tactical_stance()
				# Start the 2-second delay before dash attack
				stance_to_dash_timer = stance_to_dash_delay
				current_state = AIState.ATTACKING
			
		AIState.ATTACKING:
			# Once in attacking state, commit to the attack regardless of player position
			if current_stance != Stance.NEUTRAL:
				# Only attack after 2-second delay and cooldown is ready
				if attack_timer <= 0 and stance_to_dash_timer <= 0:
					perform_dash_attack()
			else:
				current_state = AIState.RETREATING
				retreat_timer = 1.0
				
		AIState.RETREATING:
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

func pick_new_walking_direction():
	# Pick a random direction
	var angle = randf() * 2 * PI
	walking_direction = Vector2(cos(angle), sin(angle))
	
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
	return pos.x < -425 + margin or pos.x > 425 - margin or pos.y < -325 + margin or pos.y > 325 - margin

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
		
		# Strategic stance selection based on rock-paper-scissors
		match player_stance:
			Player.Stance.NEUTRAL:
				# Player is defensive, choose random attacking stance
				var attacking_stances = [Stance.ROCK, Stance.PAPER, Stance.SCISSORS]
				current_stance = attacking_stances[randi() % attacking_stances.size()]
			Player.Stance.ROCK:
				# Counter with Paper
				current_stance = Stance.PAPER
			Player.Stance.PAPER:
				# Counter with Scissors
				current_stance = Stance.SCISSORS
			Player.Stance.SCISSORS:
				# Counter with Rock
				current_stance = Stance.ROCK
		
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
		else:
			velocity = dash_direction * dash_speed
			
		# CRITICAL FIX: Apply movement during dash
		move_and_slide()
			
		# Check for player hits during dash
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
		
		# Reset color after dash
		var tween = create_tween()
		tween.tween_interval(dash_duration)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
		# Emit attack signal
		enemy_attack.emit(current_stance, global_position)
		print("Enemy dash attacks with: ", Stance.keys()[current_stance], " towards stored target position")

func attack_during_dash():
	if player_ref and not player_ref in players_hit_this_dash:
		var distance = global_position.distance_to(player_ref.global_position)
		if distance <= attack_range:
			# Detect combat scenario: mutual attack or attack vs defense
			var is_mutual_attack = detect_mutual_attack_with_player()
			# Calculate combat result based on stance matchup and scenario
			var combat_result = calculate_combat_damage(current_stance, player_ref.current_stance, is_mutual_attack)
			
			# Handle defense point consumption
			if combat_result.player_defense_consumed:
				if player_ref.has_method("consume_defense_point"):
					if player_ref.consume_defense_point():
						print("Player blocked with defense point!")
					else:
						# No defense points left, take damage instead
						combat_result.damage = 2
						player_ref.take_damage(combat_result.damage)
				else:
					# Fallback if method doesn't exist
					player_ref.take_damage(combat_result.damage)
			elif combat_result.damage > 0:
				player_ref.take_damage(combat_result.damage)
			
			# Handle enemy stun (parry success!)
			if combat_result.enemy_stunned:
				apply_stun()
				# Create parry particle effect at enemy position
				var game_manager = get_tree().get_first_node_in_group("game_manager")
				if game_manager and game_manager.particle_manager:
					# game_manager.particle_manager.create_parry_effect(global_position)  # Disabled for cleaner combat
					pass
			
			# Add player to the list of already hit players
			players_hit_this_dash.append(player_ref)
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
	# Returns: {damage: int, enemy_stunned: bool, player_defense_consumed: bool}
	var result = {"damage": 0, "enemy_stunned": false, "player_defense_consumed": false}
	
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
		# Enemy wins
		result.damage = 2
	else:
		# Enemy loses (parry) - enemy gets stunned
		result.damage = 0
		result.enemy_stunned = true
	
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
			# No defense points left, take damage instead
			damage = 2
			take_damage(damage)
	elif damage > 0:
		take_damage(damage)
	
	# Handle player stun (enemy successfully parried!)
	if player_stunned:
		if player_ref and player_ref.has_method("apply_stun"):
			player_ref.apply_stun()
			# Create parry particle effect at player position
			var game_manager = get_tree().get_first_node_in_group("game_manager")
			if game_manager and game_manager.particle_manager:
				# game_manager.particle_manager.create_parry_effect(player_ref.global_position)  # Disabled for cleaner combat
				pass
	
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
	# Only update attack cooldown when in neutral stance (like player)
	if attack_timer > 0 and current_stance == Stance.NEUTRAL:
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
	# Update sprite texture based on stance
	match current_stance:
		Stance.NEUTRAL:
			sprite.texture = preload("res://assets/test_sprites/idle_enemy.png")
		Stance.ROCK:
			sprite.texture = preload("res://assets/test_sprites/rock_enemy.png")
		Stance.PAPER:
			sprite.texture = preload("res://assets/test_sprites/paper_enemy.png")
		Stance.SCISSORS:
			sprite.texture = preload("res://assets/test_sprites/scissor_enemy.png")
	
	stance_label.text = stance_symbols[current_stance]
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
	
	# Visual feedback for stun
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.PURPLE, 0.2)
	# Show stun indicator
	if stun_indicator:
		stun_indicator.visible = true
	print("Enemy stunned for ", stun_duration, " seconds!")

func die():
	print("Enemy died!")
	enemy_died.emit()
	queue_free()

func hide_all_indicators():
	if alert_indicator:
		alert_indicator.visible = false
	if lost_indicator:
		lost_indicator.visible = false
	# Don't hide stun indicator - it should only be controlled by stun system

func _on_detection_area_body_entered(body):
	if body is Player:
		player_ref = body
		
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
			if alert_indicator:
				alert_indicator.visible = true
			print("Enemy spotted player - ALERT!")
		else:
			# Was already in some other state, go directly to observing
			current_state = AIState.OBSERVING
			positioning_timer = randf_range(0.5, 1.0)
			print("Enemy detected player - entering tactical mode")

func _on_detection_area_body_exited(body):
	if body is Player:
		# Don't interrupt if enemy is in attacking state (committed to attack)
		if current_state != AIState.ATTACKING:
			player_ref = null
			
			# Check if we were in combat states (not just walking around)
			var was_in_combat = current_state in [AIState.ALERT, AIState.OBSERVING, AIState.POSITIONING, AIState.STANCE_SELECTION, AIState.RETREATING]
			
			if was_in_combat:
				# Show confusion before returning to patrol
				current_state = AIState.LOST_PLAYER
				lost_player_timer = lost_player_duration
				if lost_indicator:
					lost_indicator.visible = true
				print("DEBUG: Enemy confused - lost player during combat, timer set to: ", lost_player_timer)
			else:
				# Was just walking, return to walking immediately
				current_state = AIState.WALKING
				pick_new_walking_direction()
				walking_timer = direction_change_interval
				print("Enemy lost player - returning to walking")
			
			current_stance = Stance.NEUTRAL
			update_visual()

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

func _on_attack_area_body_entered(body):
	# Attack area entry is now handled in the tactical AI states
	pass
