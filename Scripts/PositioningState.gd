extends RefCounted
class_name PositioningState

# POSITIONING AI State Handler
# Manages enemy tactical positioning behavior with exact same logic as original embedded implementation

# Static function to update POSITIONING state
static func update_positioning_state(enemy: Enemy, delta: float) -> void:
	# Move to tactical position while staying in neutral
	if enemy.player_ref:
		position_tactically(enemy)
		
		# If close enough and ready to attack, select stance
		var distance = enemy.global_position.distance_to(enemy.player_ref.global_position)
		if distance <= enemy.attack_range * 1.5 and enemy.attack_timer <= 0:
			enemy.current_state = Enemy.AIState.STANCE_SELECTION
			enemy.stance_decision_timer = GameConstants.STANCE_DECISION_TIMER  # Time to decide stance
			# Debug logging for Enemy 1
			if enemy.enemy_data and enemy.enemy_data.enemy_name == "Basic Balanced Enemy":
				# Debug: Entering stance selection
				pass
		elif enemy.enemy_data and enemy.enemy_data.enemy_name == "Basic Balanced Enemy":
			# Debug: Positioning, waiting for attack window
			pass

# Static function to handle tactical positioning (extracted from position_tactically)
static func position_tactically(enemy: Enemy) -> void:
	if enemy.player_ref:
		# Only move if in neutral stance (like player)
		if enemy.current_stance != Enemy.Stance.NEUTRAL:
			enemy.apply_movement_with_rotation(Vector2.ZERO)
			return
			
		var distance = enemy.global_position.distance_to(enemy.player_ref.global_position)
		var direction = (enemy.player_ref.global_position - enemy.global_position).normalized()
		
		# Try to maintain optimal distance - close enough to attack, far enough to retreat
		if distance > enemy.attack_range * 1.2:
			# Move closer with integrated rotation
			enemy.apply_movement_with_rotation(direction * enemy.speed)
		elif distance < enemy.attack_range * 0.8:
			# Move away to optimal distance with integrated rotation
			enemy.apply_movement_with_rotation(-direction * enemy.speed * 0.7)
		else:
			# Circle around player to find good attack angle with integrated rotation
			var perpendicular = Vector2(-direction.y, direction.x)
			enemy.apply_movement_with_rotation(perpendicular * enemy.speed * 0.5)