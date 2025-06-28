extends RefCounted
class_name StunnedState

# STUNNED AI State Handler
# Manages enemy stunned behavior with exact same logic as original embedded implementation

# Static function to update STUNNED state
static func update_stunned_state(enemy: Enemy, delta: float) -> void:
	enemy.velocity = Vector2.ZERO
	# Check if stun timer is done
	if enemy.stun_timer <= 0:
		enemy.current_state = Enemy.AIState.RETREATING
		enemy.retreat_timer = GameConstants.RETREAT_TIMER
		# Hide stun indicator when stun ends
		if enemy.stun_indicator:
			enemy.stun_indicator.visible = false

# Static function to handle stunned movement prevention in dash system
static func prevent_dash_movement_when_stunned(enemy: Enemy) -> bool:
	# No dash movement allowed when stunned
	if enemy.current_state == Enemy.AIState.STUNNED:
		if enemy.is_dashing:
			# Cancel ongoing dash when stunned
			enemy.is_dashing = false
			enemy.dash_timer = 0.0
			enemy.velocity = Vector2.ZERO
		return true  # Return true to indicate movement was prevented
	return false  # Return false to indicate normal movement should continue