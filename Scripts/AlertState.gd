extends RefCounted
class_name AlertState

# ALERT AI State Handler
# Manages enemy alert behavior with exact same logic as original embedded implementation

# Static function to update ALERT state
static func update_alert_state(enemy: Enemy, delta: float) -> void:
	# Stand still and show alert - brief pause before engaging
	enemy.velocity = Vector2.ZERO
	enemy.current_stance = Enemy.Stance.NEUTRAL
	
	# Check if alert time is over
	if enemy.alert_timer <= 0:
		# Hide alert indicator
		if enemy.alert_indicator:
			enemy.alert_indicator.visible = false
		enemy.is_alerting = false
		
		# Start observing player
		enemy.current_state = Enemy.AIState.OBSERVING
		enemy.positioning_timer = randf_range(0.01, 0.05)  # Near-instant reaction
		
		# Debug logging for Enemy 1
		if enemy.enemy_data and enemy.enemy_data.enemy_name == "Basic Balanced Enemy":
			print("AI STATE [%s]: ALERT → OBSERVING (timer: %.3f)" % [enemy.enemy_data.enemy_name, enemy.positioning_timer])

# Static function to check if enemy is currently alerting
static func is_alerting(enemy: Enemy) -> bool:
	return enemy.current_state == Enemy.AIState.ALERT and enemy.is_alerting

# Static function to start alert state
static func start_alert_state(enemy: Enemy, alert_duration: float) -> void:
	enemy.current_state = Enemy.AIState.ALERT
	enemy.is_alerting = true
	enemy.alert_timer = alert_duration
	
	# Show alert indicator
	if enemy.alert_indicator:
		enemy.alert_indicator.visible = true