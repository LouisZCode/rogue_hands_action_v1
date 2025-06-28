extends RefCounted
class_name RetreatingState

# RETREATING AI State Handler
# Manages enemy retreating behavior with exact same logic as original embedded implementation

# Static function to update RETREATING state
static func update_retreating_state(enemy: Enemy, delta: float) -> void:
	# Dash preview hiding removed for complete overhaul
	# Move away and return to neutral
	if enemy.player_ref:
		retreat_from_player(enemy)
		
	if enemy.retreat_timer <= 0:
		enemy.current_stance = Enemy.Stance.NEUTRAL
		enemy.update_visual()
		# Return to walking if no player, otherwise keep observing
		if enemy.player_ref:
			enemy.current_state = Enemy.AIState.OBSERVING
			enemy.positioning_timer = randf_range(0.5, 1.5)
		else:
			# Show confusion after retreat before going back to patrol
			enemy.current_state = Enemy.AIState.LOST_PLAYER
			enemy.lost_player_timer = enemy.lost_player_duration
			if enemy.lost_indicator:
				enemy.lost_indicator.visible = true
			# Retreat finished, showing confusion

# Static function to handle retreat movement (extracted from retreat_from_player)
static func retreat_from_player(enemy: Enemy) -> void:
	if enemy.player_ref:
		# Only move if in neutral stance (like player)
		if enemy.current_stance != Enemy.Stance.NEUTRAL:
			enemy.apply_movement_with_rotation(Vector2.ZERO)
			return
			
		var direction = (enemy.global_position - enemy.player_ref.global_position).normalized()
		enemy.apply_movement_with_rotation(direction * enemy.speed * 0.8)