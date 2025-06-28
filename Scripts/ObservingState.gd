extends RefCounted
class_name ObservingState

# OBSERVING AI State Handler
# Manages enemy observation behavior with exact same logic as original embedded implementation

# Static function to update OBSERVING state
static func update_observing_state(enemy: Enemy, delta: float) -> void:
	# Stand still and observe player behavior
	enemy.velocity = Vector2.ZERO
	observe_player(enemy)
	
	# After observing, decide on positioning
	if enemy.positioning_timer <= 0:
		enemy.current_state = Enemy.AIState.POSITIONING
		enemy.positioning_timer = randf_range(0.1, 0.3)  # Quick positioning
		# Debug logging for Enemy 1
		if enemy.enemy_data and enemy.enemy_data.enemy_name == "Basic Balanced Enemy":
			print("AI STATE [%s]: OBSERVING → POSITIONING (timer: %.3f)" % [enemy.enemy_data.enemy_name, enemy.positioning_timer])

# Static function to observe player behavior (extracted from observe_player)
static func observe_player(enemy: Enemy) -> void:
	if enemy.player_ref:
		# Track player's stance changes
		if enemy.player_ref.current_stance != enemy.last_player_stance:
			enemy.last_player_stance = enemy.player_ref.current_stance
			# Debug: Player stance change observed