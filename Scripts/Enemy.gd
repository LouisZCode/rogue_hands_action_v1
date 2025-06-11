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
var max_health: int = 60
var current_health: int = 60

# AI State - Enhanced tactical system
enum AIState { IDLE, OBSERVING, POSITIONING, STANCE_SELECTION, ATTACKING, RETREATING, STUNNED }
var current_state: AIState = AIState.IDLE
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

# References
@onready var sprite: ColorRect = $Sprite
@onready var stance_label: Label = $StanceLabel
@onready var health_bar: ProgressBar = $HealthBar
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

func _ready():
	update_visual()
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	
func _physics_process(delta):
	update_ai(delta)
	update_timers(delta)
	handle_dash_movement(delta)

func update_ai(delta):
	if is_dashing:
		return  # Don't update AI during dash
		
	match current_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			current_stance = Stance.NEUTRAL
			
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
				current_state = AIState.ATTACKING
			
		AIState.ATTACKING:
			if player_ref and current_stance != Stance.NEUTRAL:
				var distance = global_position.distance_to(player_ref.global_position)
				if distance <= attack_range:
					if attack_timer <= 0:
						perform_dash_attack()
				else:
					# Move closer to attack
					chase_player()
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
				current_state = AIState.OBSERVING
				positioning_timer = randf_range(0.5, 1.5)
				
		AIState.STUNNED:
			velocity = Vector2.ZERO
			# Stunned state handled by timer
	
	if not is_dashing:
		move_and_slide()

# New AI methods for tactical combat
func observe_player():
	if player_ref:
		# Track player's stance changes
		if player_ref.current_stance != last_player_stance:
			last_player_stance = player_ref.current_stance
			print("Enemy observed player change to: ", Player.Stance.keys()[last_player_stance])

func position_tactically():
	if player_ref:
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

func chase_player():
	if player_ref:
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * speed

func retreat_from_player():
	if player_ref:
		var direction = (global_position - player_ref.global_position).normalized()
		velocity = direction * speed * 0.8

func handle_dash_movement(delta):
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
			
		# Check for player hits during dash
		attack_during_dash()

func perform_dash_attack():
	if player_ref and current_stance != Stance.NEUTRAL:
		# Calculate attack direction
		var direction = (player_ref.global_position - global_position).normalized()
		
		# Start dash attack
		is_dashing = true
		dash_direction = direction
		dash_timer = dash_duration
		attack_timer = attack_cooldown
		
		# Visual feedback
		var dash_color = stance_colors[current_stance].lerp(Color.WHITE, 0.5)
		sprite.modulate = dash_color
		
		# Reset color after dash
		var tween = create_tween()
		tween.tween_interval(dash_duration)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
		# Emit attack signal
		enemy_attack.emit(current_stance, global_position)
		print("Enemy dash attacks with: ", Stance.keys()[current_stance])

func attack_during_dash():
	if player_ref:
		var distance = global_position.distance_to(player_ref.global_position)
		if distance <= attack_range:
			# Deal damage based on stance matchup
			var damage = calculate_combat_damage(current_stance, player_ref.current_stance)
			if damage > 0:
				player_ref.take_damage(damage)
				print("Enemy hit player for ", damage, " damage during dash")

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

func calculate_combat_damage(enemy_stance: Stance, player_stance) -> int:
	# Enemy attacks player - proper Rock-Paper-Scissors logic for all stances
	# Enemy enum: 0=NEUTRAL, 1=ROCK, 2=PAPER, 3=SCISSORS
	# Player enum: 0=NEUTRAL, 1=ROCK, 2=PAPER, 3=SCISSORS
	var player_stance_int = int(player_stance)
	var enemy_stance_int = int(enemy_stance)
	
	# Player in neutral takes base damage (will be reduced in Player.take_damage())
	if player_stance_int == 0:
		return 20  # Base damage for neutral stance
	
	# Enemy in neutral shouldn't attack (but handle just in case)
	if enemy_stance_int == 0:
		return 5  # Minimal damage if somehow attacking in neutral
	
	# Combat logic: Full rock-paper-scissors for all enemy stances
	if enemy_stance_int == player_stance_int:
		return 10  # Tie damage
	elif (enemy_stance_int == 1 and player_stance_int == 3) or \
		 (enemy_stance_int == 2 and player_stance_int == 1) or \
		 (enemy_stance_int == 3 and player_stance_int == 2):
		return 30  # Enemy wins - full damage
	else:
		return 5   # Enemy loses - minimal damage

func take_damage_from_player(player_stance, attack_position: Vector2):
	# Convert player stance to comparable format
	var damage = 0
	var result = ""
	
	# Proper Rock-Paper-Scissors logic using integers for all enemy stances
	# Player enum: 0=NEUTRAL, 1=ROCK, 2=PAPER, 3=SCISSORS
	# Enemy enum: 0=NEUTRAL, 1=ROCK, 2=PAPER, 3=SCISSORS
	var player_stance_int = int(player_stance)
	var enemy_stance_int = int(current_stance)  # Enemy can now use any stance
	
	# Players in neutral stance cannot attack (this shouldn't happen due to attack restrictions)
	if player_stance_int == 0:  # NEUTRAL
		damage = 0
		result = "NO DAMAGE - NEUTRAL STANCE"
	elif player_stance_int == enemy_stance_int:  # Tie
		damage = 10  # Tie
		result = "TIE - " + Stance.keys()[current_stance] + " vs " + Player.Stance.keys()[player_stance]
	elif (player_stance_int == 1 and enemy_stance_int == 3) or \
		 (player_stance_int == 2 and enemy_stance_int == 1) or \
		 (player_stance_int == 3 and enemy_stance_int == 2):
		damage = 30  # Player wins
		result = "PLAYER WINS - " + Player.Stance.keys()[player_stance] + " beats " + Stance.keys()[current_stance]
	else:
		damage = 5   # Player loses (reduced damage)
		result = "PLAYER LOSES - " + Stance.keys()[current_stance] + " beats " + Player.Stance.keys()[player_stance]
	
	take_damage(damage)
	print("Combat: Player ", Player.Stance.keys()[player_stance], " vs Enemy ", Stance.keys()[current_stance], " - Damage: ", damage, " - ", result)

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	update_health_bar()
	
	# Visual feedback for taking damage
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
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

func update_visual():
	sprite.color = stance_colors[current_stance]
	stance_label.text = stance_symbols[current_stance]
	update_health_bar()

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

func die():
	print("Enemy died!")
	enemy_died.emit()
	queue_free()

func _on_detection_area_body_entered(body):
	if body is Player:
		player_ref = body
		current_state = AIState.OBSERVING
		positioning_timer = randf_range(0.5, 1.0)
		print("Enemy detected player - entering tactical mode")

func _on_detection_area_body_exited(body):
	if body is Player:
		player_ref = null
		current_state = AIState.IDLE
		current_stance = Stance.NEUTRAL
		update_visual()
		print("Enemy lost player - returning to idle")

func _on_attack_area_body_entered(body):
	# Attack area entry is now handled in the tactical AI states
	pass
