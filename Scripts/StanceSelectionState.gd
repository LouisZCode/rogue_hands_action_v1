extends RefCounted
class_name StanceSelectionState

# STANCE_SELECTION AI State Handler
# Manages enemy stance selection behavior with exact same logic as original embedded implementation

# Static function to update STANCE_SELECTION state
static func update_stance_selection_state(enemy: Enemy, delta: float) -> void:
	# Stop moving and select counter-stance
	enemy.velocity = Vector2.ZERO
	if enemy.stance_decision_timer <= 0:
		select_tactical_stance(enemy)
		# Start the 2-second delay before dash attack
		enemy.stance_to_dash_timer = enemy.stance_to_dash_delay
		enemy.current_state = Enemy.AIState.ATTACKING
		# Debug logging for Enemy 1
		if enemy.enemy_data and enemy.enemy_data.enemy_name == "Basic Balanced Enemy":
			# Debug: Starting attack with selected stance
			pass

# Static function to handle tactical stance selection (extracted from select_tactical_stance)
static func select_tactical_stance(enemy: Enemy) -> void:
	if enemy.player_ref:
		var player_stance = enemy.player_ref.current_stance
		
		# Store the player's position at the moment of stance selection
		enemy.target_attack_position = enemy.player_ref.global_position
		
		print("ENEMY: Stance selection - Enemy position: ", enemy.global_position, " - Target position: ", enemy.target_attack_position)
		
		# Debug mode: Always use Rock for testing
		if enemy.debug_rock_only:
			enemy.current_stance = Enemy.Stance.ROCK
			enemy.update_visual()
			print("ENEMY: Selected ROCK (debug mode) vs player's ", Player.Stance.keys()[player_stance])
			print("ENEMY: Attack trajectory from ", enemy.global_position, " to ", enemy.target_attack_position)
			return
		
		# Stance selection based on CSV probabilities
		enemy.current_stance = select_weighted_stance(enemy)
		
		enemy.update_visual()
		# Debug: Stance selection complete
		# Debug: Target position locked

# Static function to select stance based on CSV probability weights (extracted from select_weighted_stance)
static func select_weighted_stance(enemy: Enemy) -> Enemy.Stance:
	# Select stance based on CSV probability weights
	if not enemy.enemy_data:
		# Fallback to random if no data
		var stances = [Enemy.Stance.NEUTRAL, Enemy.Stance.ROCK, Enemy.Stance.PAPER, Enemy.Stance.SCISSORS]
		return stances[randi() % stances.size()]
	
	# Get probabilities from enemy data
	var total_weight = enemy.enemy_data.neutral_probability + enemy.enemy_data.rock_probability + enemy.enemy_data.paper_probability + enemy.enemy_data.scissors_probability
	
	if total_weight <= 0:
		# Fallback to balanced if all weights are 0
		return Enemy.Stance.ROCK
	
	# Generate random number between 0 and total weight
	var random_value = randf() * total_weight
	var cumulative_weight = 0.0
	
	# Check neutral stance
	cumulative_weight += enemy.enemy_data.neutral_probability
	if random_value <= cumulative_weight:
		return Enemy.Stance.NEUTRAL
	
	# Check rock stance
	cumulative_weight += enemy.enemy_data.rock_probability
	if random_value <= cumulative_weight:
		return Enemy.Stance.ROCK
	
	# Check paper stance
	cumulative_weight += enemy.enemy_data.paper_probability
	if random_value <= cumulative_weight:
		return Enemy.Stance.PAPER
	
	# Default to scissors (or if rounding errors)
	return Enemy.Stance.SCISSORS