extends RefCounted
class_name WalkingState

# WALKING AI State Handler
# Manages enemy walking behavior with exact same logic as original embedded implementation

# Static function to update WALKING state
static func update_walking_state(enemy: Enemy, delta: float) -> void:
	# Random walking behavior when no player detected
	enemy.current_stance = Enemy.Stance.NEUTRAL
	
	# Hide any lingering indicators
	enemy.hide_all_indicators()
	
	# Handle walking movement logic
	handle_walking_movement(enemy, delta)

# Static function to handle walking movement (extracted from handle_walking_movement)
static func handle_walking_movement(enemy: Enemy, delta: float) -> void:
	# Change direction periodically or if hitting boundaries
	if enemy.walking_timer <= 0 or enemy.is_near_boundary():
		# 40% chance to go idle instead of continuing to walk
		if randf() < 0.4:
			enemy.current_state = Enemy.AIState.IDLE
			enemy.idle_timer = enemy.idle_duration_min  # Fixed 3-second duration for consistent idle animation
			# Start deceleration when going idle
			enemy.current_speed = 0.0
			return
		else:
			WalkingState.pick_new_walking_direction(enemy)
			enemy.walking_timer = enemy.direction_change_interval + randf_range(-0.5, 0.5)  # Add some randomness
	
	# Smooth movement with acceleration/deceleration and integrated rotation
	if enemy.walking_direction.length() > 0.1:
		# Accelerate toward walking speed
		var target_speed = enemy.walking_speed
		enemy.current_speed = move_toward(enemy.current_speed, target_speed, enemy.acceleration * enemy.get_process_delta_time())
		var new_velocity = enemy.walking_direction.normalized() * enemy.current_speed
		enemy.apply_movement_with_rotation(new_velocity)
		
		# Update facing direction gradually based on movement
		if enemy.velocity.length() > 0.1:
			var target_facing = enemy.velocity.normalized()
			enemy.facing_direction = enemy.facing_direction.lerp(target_facing, 3.0 * enemy.get_process_delta_time()).normalized()
	else:
		# Decelerate when no direction
		enemy.current_speed = move_toward(enemy.current_speed, 0.0, enemy.deceleration * enemy.get_process_delta_time())
		if enemy.velocity.length() > 0 and enemy.current_speed > 0:
			enemy.apply_movement_with_rotation(enemy.velocity.normalized() * enemy.current_speed)
		else:
			enemy.apply_movement_with_rotation(Vector2.ZERO)

# Static function to pick new walking direction (extracted from pick_new_walking_direction)
static func pick_new_walking_direction(enemy: Enemy) -> void:
	# Pick a random direction
	var angle = randf() * 2 * PI
	enemy.walking_direction = Vector2(cos(angle), sin(angle))
	
	# Make sure we're not walking directly into a wall
	var test_position = enemy.global_position + enemy.walking_direction * 100
	if enemy.is_position_near_boundary(test_position):
		# Pick direction towards center instead
		enemy.walking_direction = (Vector2.ZERO - enemy.global_position).normalized()
		# Add some randomness to avoid getting stuck
		var random_offset = Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
		enemy.walking_direction = (enemy.walking_direction + random_offset).normalized()
	
	# Update facing direction immediately
	enemy.facing_direction = enemy.walking_direction.normalized()

# Static function to check if enemy should transition from LOST_PLAYER back to WALKING
static func should_return_to_walking_from_lost_player(enemy: Enemy) -> bool:
	return enemy.lost_player_timer <= 0

# Static function to transition from LOST_PLAYER to WALKING
static func transition_from_lost_player_to_walking(enemy: Enemy) -> void:
	# Hide lost indicator
	if enemy.lost_indicator:
		enemy.lost_indicator.visible = false
	
	# Reset detection range when giving up search
	enemy.reset_detection_range()
	
	# Return to walking
	enemy.current_state = Enemy.AIState.WALKING
	WalkingState.pick_new_walking_direction(enemy)
	enemy.walking_timer = enemy.direction_change_interval
