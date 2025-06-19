extends Node2D
class_name DamageNumber

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

var movement_tween: Tween
var fade_tween: Tween

func _ready():
	# Connect timer to cleanup
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func show_damage(amount: int, category: int, position: Vector2, is_tie: bool = false, is_player_taking_damage: bool = true):
	# Set position
	global_position = position
	
	# Configure text and color based on damage type
	if is_tie:
		label.text = "TIE!"
		label.label_settings.font_color = Color.YELLOW
		label.label_settings.font_size = 40  # Doubled from 20
	elif amount <= 0:
		label.text = "BLOCK!"
		label.label_settings.font_color = Color.CYAN
		label.label_settings.font_size = 36  # Doubled from 18
	else:
		label.text = str(amount)
		# Color based on damage category and direction
		if is_player_taking_damage:
			# Red shades for damage taken by player
			match category:
				1: # LIGHT
					label.label_settings.font_color = Color.ORANGE_RED
					label.label_settings.font_size = 36  # Doubled from 18
				2: # NORMAL  
					label.label_settings.font_color = Color.RED
					label.label_settings.font_size = 48  # Doubled from 24
				3: # HEAVY
					label.label_settings.font_color = Color.DARK_RED
					label.label_settings.font_size = 56  # Doubled from 28
		else:
			# Blue shades for damage dealt by player
			match category:
				1: # LIGHT
					label.label_settings.font_color = Color.LIGHT_BLUE
					label.label_settings.font_size = 36  # Doubled from 18
				2: # NORMAL  
					label.label_settings.font_color = Color.BLUE
					label.label_settings.font_size = 48  # Doubled from 24
				3: # HEAVY
					label.label_settings.font_color = Color.DARK_BLUE
					label.label_settings.font_size = 56  # Doubled from 28
	
	# Animate movement (float upward with slight random spread) - 60% closer
	var random_x_offset = randf_range(-8, 8)  # Reduced from ±20 to ±8
	var target_position = global_position + Vector2(random_x_offset, -32)  # Reduced from -80 to -32
	
	movement_tween = create_tween()
	movement_tween.set_ease(Tween.EASE_OUT)
	movement_tween.set_trans(Tween.TRANS_QUART)
	movement_tween.tween_property(self, "global_position", target_position, 1.5)
	
	# Animate fade out
	fade_tween = create_tween()
	fade_tween.tween_interval(0.8)  # Stay visible for a moment
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.7)

func show_healing(amount: int, position: Vector2):
	# Set position
	global_position = position
	
	# Configure for healing
	label.text = "+" + str(amount)
	label.label_settings.font_color = Color.GREEN
	label.label_settings.font_size = 40  # Doubled from 20
	
	# Animate movement (float upward) - 60% closer
	var target_position = global_position + Vector2(0, -24)  # Reduced from -60 to -24
	
	movement_tween = create_tween()
	movement_tween.set_ease(Tween.EASE_OUT)
	movement_tween.set_trans(Tween.TRANS_QUART)
	movement_tween.tween_property(self, "global_position", target_position, 1.2)
	
	# Animate fade out
	fade_tween = create_tween()
	fade_tween.tween_interval(0.6)
	fade_tween.tween_property(label, "modulate:a", 0.0, 0.6)

func _on_timer_timeout():
	# Clean up the damage number
	if movement_tween:
		movement_tween.kill()
	if fade_tween:
		fade_tween.kill()
	queue_free()