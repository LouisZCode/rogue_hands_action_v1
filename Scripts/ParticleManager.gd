extends Node2D
class_name ParticleManager

# Particle effects management for the game
var hit_particles_scene = preload("res://scenes/HitParticles.tscn")
var gesture_particles_scene = preload("res://scenes/GestureParticles.tscn")

# Singleton tracking
static var instance_count = 0

func _ready():
	instance_count += 1
	if instance_count == 1:
		print("ParticleManager initialized with particle scenes loaded")
	else:
		print("WARNING: Multiple ParticleManager instances! Count: ", instance_count)

func _exit_tree():
	instance_count -= 1

func create_hit_effect(pos: Vector2):
	var particles = hit_particles_scene.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	particles.emitting = true
	
	# Auto-cleanup after particle lifetime
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = particles.lifetime + 0.5
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(cleanup_timer)
	cleanup_timer.start()
	
	print("Hit particles created at: ", pos)

func create_stance_change_effect(pos: Vector2, stance_color: Color):
	var particles = gesture_particles_scene.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	
	# Ensure we have a ParticleProcessMaterial
	if not particles.process_material:
		particles.process_material = ParticleProcessMaterial.new()
	
	var material = particles.process_material as ParticleProcessMaterial
	if material:
		material.color = stance_color
	
	particles.emitting = true
	
	# Auto-cleanup after particle lifetime
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = particles.lifetime + 0.5
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(cleanup_timer)
	cleanup_timer.start()
	
	print("Stance change particles created at: ", pos, " with color: ", stance_color)

func create_death_effect(pos: Vector2):
	# Use hit particles for death but with longer duration and red color
	var particles = hit_particles_scene.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	particles.amount = 100  # More particles for dramatic effect
	
	# Ensure we have a ParticleProcessMaterial
	if not particles.process_material:
		particles.process_material = ParticleProcessMaterial.new()
	
	var material = particles.process_material as ParticleProcessMaterial
	if material:
		material.color = Color.RED
	
	particles.emitting = true
	
	# Longer cleanup time for death effect
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = particles.lifetime + 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(cleanup_timer)
	cleanup_timer.start()
	
	print("Death particles created at: ", pos)

func create_attack_effect(pos: Vector2, direction: Vector2):
	var particles = gesture_particles_scene.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	
	# Ensure we have a ParticleProcessMaterial
	if not particles.process_material:
		particles.process_material = ParticleProcessMaterial.new()
	
	var material = particles.process_material as ParticleProcessMaterial
	if material:
		# Set particle direction based on attack direction
		var angle_rad = direction.angle()
		material.direction = Vector3(cos(angle_rad), sin(angle_rad), 0)
		material.spread = 30.0  # Narrower spread for directional attack
		material.color = Color.YELLOW
	
	particles.emitting = true
	
	# Auto-cleanup
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = particles.lifetime + 0.5
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(cleanup_timer)
	cleanup_timer.start()
	
	print("Attack particles created at: ", pos, " in direction: ", direction)

func create_parry_effect(pos: Vector2):
	# Use gesture particles for parry with special blue/white color for tactical highlight
	var particles = gesture_particles_scene.instantiate()
	get_tree().current_scene.add_child(particles)
	particles.global_position = pos
	
	# Ensure we have a ParticleProcessMaterial
	if not particles.process_material:
		particles.process_material = ParticleProcessMaterial.new()
	
	var material = particles.process_material as ParticleProcessMaterial
	if material:
		material.color = Color.CYAN  # Bright blue-white for parry success
		material.spread = 180.0  # Wide spread for dramatic effect
	
	particles.emitting = true
	
	# Auto-cleanup
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = particles.lifetime + 0.5
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): particles.queue_free())
	particles.add_child(cleanup_timer)
	cleanup_timer.start()
	
	print("Parry particles created at: ", pos)
