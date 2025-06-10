extends CharacterBody2D
class_name Enemy

# AI and movement variables
@export var speed: float = 100.0
@export var detection_range: float = 150.0
@export var attack_range: float = 50.0

# Combat variables  
enum Stance { ROCK, PAPER, SCISSORS }
var current_stance: Stance = Stance.ROCK  # Enemy only uses Rock
var max_health: int = 60
var current_health: int = 60

# AI State
enum AIState { IDLE, CHASING, ATTACKING, STUNNED }
var current_state: AIState = AIState.IDLE
var player_ref: Player = null
var attack_cooldown: float = 2.0
var attack_timer: float = 0.0

# References
@onready var sprite: ColorRect = $Sprite
@onready var stance_label: Label = $StanceLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea

# Stance colors and symbols (enemy only uses Rock)
var stance_colors = {
	Stance.ROCK: Color.DARK_RED,
	Stance.PAPER: Color.PINK,
	Stance.SCISSORS: Color.ORANGE
}

var stance_symbols = {
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
	update_attack_timer(delta)

func update_ai(delta):
	match current_state:
		AIState.IDLE:
			velocity = Vector2.ZERO
			
		AIState.CHASING:
			if player_ref:
				chase_player()
				# Check if close enough to attack
				var distance = global_position.distance_to(player_ref.global_position)
				if distance <= attack_range:
					current_state = AIState.ATTACKING
					
		AIState.ATTACKING:
			if player_ref:
				var distance = global_position.distance_to(player_ref.global_position)
				if distance > attack_range:
					current_state = AIState.CHASING
				elif attack_timer <= 0:
					perform_attack()
					attack_timer = attack_cooldown
			else:
				current_state = AIState.IDLE
				
		AIState.STUNNED:
			velocity = Vector2.ZERO
			# Stunned state handled by timer
	
	move_and_slide()

func chase_player():
	if player_ref:
		var direction = (player_ref.global_position - global_position).normalized()
		velocity = direction * speed

func perform_attack():
	if player_ref:
		# Emit attack signal
		enemy_attack.emit(current_stance, global_position)
		
		# Deal damage to player if in range
		var distance = global_position.distance_to(player_ref.global_position)
		if distance <= attack_range:
			# Combat resolution: Enemy always uses Rock
			# Convert player stance to enemy stance enum for comparison
			var player_stance_as_enemy = current_stance  # Enemy is always Rock
			var damage = calculate_damage(current_stance, current_stance)  # Simplified for now
			if damage > 0:
				player_ref.take_damage(damage)
			
			# Visual attack feedback
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.1)
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

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

func take_damage_from_player(player_stance, attack_position: Vector2):
	# Convert player stance to comparable format
	var enemy_stance_equivalent = current_stance  # Enemy is always Rock
	var damage = 0
	
	# Manual Rock-Paper-Scissors logic using integers
	var player_stance_int = int(player_stance)  # 0=Rock, 1=Paper, 2=Scissors
	var enemy_stance_int = 0  # Enemy always uses Rock
	
	if player_stance_int == enemy_stance_int:
		damage = 10  # Tie
		var result = "TIE"
	elif (player_stance_int == 1 and enemy_stance_int == 0):  # Paper beats Rock
		damage = 30  # Player wins
		var result = "PLAYER WINS"
	elif (player_stance_int == 0 and enemy_stance_int == 2):  # Rock beats Scissors
		damage = 30  # Player wins
		var result = "PLAYER WINS"
	elif (player_stance_int == 2 and enemy_stance_int == 1):  # Scissors beats Paper
		damage = 30  # Player wins  
		var result = "PLAYER WINS"
	else:
		damage = 5   # Player loses
		var result = "ENEMY WINS"
	
	take_damage(damage)
	print("Combat: Player Stance ", player_stance_int, " vs Enemy Rock - Damage: ", damage)

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
		stun_timer.tween_callback(func(): current_state = AIState.CHASING).set_delay(0.5)

func update_attack_timer(delta):
	if attack_timer > 0:
		attack_timer -= delta

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
		current_state = AIState.CHASING

func _on_detection_area_body_exited(body):
	if body is Player:
		player_ref = null
		current_state = AIState.IDLE

func _on_attack_area_body_entered(body):
	if body is Player and current_state == AIState.CHASING:
		current_state = AIState.ATTACKING
