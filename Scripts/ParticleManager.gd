extends Node2D
class_name ParticleManager

# Particle effects management for the game
# Placeholder for future particle effects

func _ready():
	print("ParticleManager initialized - ready for visual effects")

func create_hit_effect(pos: Vector2):
	print("Hit effect at position: ", pos)
	# Future: Create particle effect at position

func create_stance_change_effect(pos: Vector2, stance_color: Color):
	print("Stance change effect at position: ", pos, " with color: ", stance_color)
	# Future: Create stance change particle effect

func create_death_effect(pos: Vector2):
	print("Death effect at position: ", pos)
	# Future: Create death particle effect

func create_attack_effect(pos: Vector2, direction: Vector2):
	print("Attack effect at position: ", pos, " in direction: ", direction)
	# Future: Create attack particle effect