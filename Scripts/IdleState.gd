extends RefCounted
class_name IdleState

# IDLE AI State Handler
# Manages enemy idle behavior with exact same logic as original embedded implementation

# Static function to update IDLE state
static func update_idle_state(enemy: Enemy, delta: float) -> void:
	# Smooth deceleration to stop
	enemy.current_speed = move_toward(enemy.current_speed, 0.0, enemy.deceleration * delta)
	
	if enemy.velocity.length() > 0 and enemy.current_speed > 0:
		enemy.velocity = enemy.velocity.normalized() * enemy.current_speed
	else:
		enemy.velocity = Vector2.ZERO
	
	# Force neutral stance during idle
	enemy.current_stance = Enemy.Stance.NEUTRAL
	
	# Hide any lingering indicators
	enemy.hide_all_indicators()
	
	# Check if idle time is over
	if enemy.idle_timer <= 0:
		# Idle timer expired, returning to walking state
		enemy.current_state = Enemy.AIState.WALKING
		enemy.pick_new_walking_direction()
		enemy.walking_timer = enemy.direction_change_interval

# Static function to check if idle state should be protected from interruption
static func is_idle_protected(enemy: Enemy) -> bool:
	return enemy.current_state == Enemy.AIState.IDLE and enemy.idle_timer > 0

# Static function to check if enemy can be detected (respects idle protection)
static func can_be_detected_during_idle(enemy: Enemy) -> bool:
	return enemy.current_state != Enemy.AIState.IDLE or enemy.idle_timer <= 0

# Static function to determine if enemy was in patrolling state (for detection logic)
static func was_patrolling(enemy: Enemy) -> bool:
	return enemy.current_state == Enemy.AIState.WALKING or (enemy.current_state == Enemy.AIState.IDLE and enemy.idle_timer <= 0)

# Static function to handle idle animation protection
static func should_maintain_idle_animation(enemy: Enemy) -> bool:
	return enemy.current_state == Enemy.AIState.IDLE and enemy.idle_timer > 0