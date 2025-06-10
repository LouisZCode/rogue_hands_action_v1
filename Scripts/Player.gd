extends CharacterBody2D
class_name Player

# Movement variables
@export var speed: float = 200.0

# Combat variables
enum Stance { ROCK, PAPER, SCISSORS }
var current_stance: Stance = Stance.ROCK
var max_health: int = 100
var current_health: int = 100

# References
@onready var sprite: ColorRect = $Sprite
@onready var stance_label: Label = $StanceLabel
@onready var attack_area: Area2D = $AttackArea

# Stance colors and symbols
var stance_colors = {
	Stance.ROCK: Color.GRAY,
	Stance.PAPER: Color.WHITE, 
	Stance.SCISSORS: Color.YELLOW
}

var stance_symbols = {
	Stance.ROCK: "✊",
	Stance.PAPER: "✋",
	Stance.SCISSORS: "✌️"
}

signal health_changed(new_health: int)
signal stance_changed(new_stance: Stance)
signal player_attack(attacker_stance: Stance, attack_position: Vector2)

func _ready():
	update_stance_visual()
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	
func _physics_process(delta):
	handle_movement(delta)
	handle_input()

func handle_movement(delta):
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
	
	move_and_slide()

func handle_input():
	# Stance selection
	if Input.is_action_just_pressed("gesture_rock"):
		change_stance(Stance.ROCK)
	elif Input.is_action_just_pressed("gesture_paper"):
		change_stance(Stance.PAPER)
	elif Input.is_action_just_pressed("gesture_scissors"):  
		change_stance(Stance.SCISSORS)
	
	# Attack
	if Input.is_action_just_pressed("attack"):
		perform_attack()

func change_stance(new_stance: Stance):
	if current_stance != new_stance:
		current_stance = new_stance
		update_stance_visual()
		stance_changed.emit(current_stance)

func update_stance_visual():
	sprite.color = stance_colors[current_stance]
	stance_label.text = stance_symbols[current_stance]

func perform_attack():
	# Emit signal with current stance and position
	player_attack.emit(current_stance, global_position)
	
	# Check for enemies in attack range
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("take_damage_from_player"):
			body.take_damage_from_player(current_stance, global_position)

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	
	# Visual feedback for taking damage
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func die():
	print("Player died!")
	# Handle player death (restart game, etc.)
	get_tree().reload_current_scene()

func _on_attack_area_body_entered(body):
	# This is called when something enters attack range
	pass