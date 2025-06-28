extends RefCounted
class_name AttackingState

# ATTACKING AI State Handler
# Manages enemy attacking behavior with exact same logic as original embedded implementation

# Static function to update ATTACKING state
static func update_attacking_state(enemy: Enemy, delta: float) -> void:
	# Dash trajectory display removed for complete overhaul
	# Once in attacking state, commit to the attack regardless of player position
	if enemy.current_stance != Enemy.Stance.NEUTRAL:
		# Only attack after 2-second delay and cooldown is ready
		if enemy.attack_timer <= 0 and enemy.stance_to_dash_timer <= 0:
			perform_dash_attack(enemy)
	else:
		enemy.current_state = Enemy.AIState.RETREATING
		enemy.retreat_timer = GameConstants.RETREAT_TIMER
		# Hide attack timer when exiting attacking state
		if enemy.attack_timer_bar:
			enemy.attack_timer_bar.visible = false
		# Dash preview hiding removed for complete overhaul

# Static function to perform dash attack (extracted from perform_dash_attack)
static func perform_dash_attack(enemy: Enemy) -> void:
	if enemy.current_stance != Enemy.Stance.NEUTRAL:
		# Calculate attack direction using stored target position
		var direction = (enemy.target_attack_position - enemy.global_position).normalized()
		
		# Start dash attack
		enemy.is_dashing = true
		enemy.dash_direction = direction
		enemy.dash_timer = enemy.dash_duration
		enemy.attack_timer = enemy.attack_cooldown
		
		# Clear the list of players hit this dash
		enemy.players_hit_this_dash.clear()
		
		# Visual feedback
		var dash_color = enemy.stance_colors[enemy.current_stance].lerp(Color.WHITE, 0.5)
		enemy.sprite.modulate = dash_color
		
		# DEBUG: Make enemy glow bright red during attack for visibility
		if enemy.debug_attack_range:
			enemy.sprite.modulate = Color.RED
			enemy.debug_draw_attack_area()
			enemy.queue_redraw()
		
		# Reset color after dash
		var tween = enemy.create_tween()
		tween.tween_interval(enemy.dash_duration)
		tween.tween_property(enemy.sprite, "modulate", Color.WHITE, 0.1)
		
		# Emit attack signal
		enemy.enemy_attack.emit(enemy.current_stance, enemy.global_position)
		# Debug: Dash attack initiated

# Static function to handle attack collision during dash (extracted from attack_during_dash)
static func attack_during_dash(enemy: Enemy) -> void:
	# DEBUG: Add comprehensive logging
	# print("=== ENEMY ATTACK_DURING_DASH DEBUG ===")
	# print("Enemy position: ", enemy.global_position)
	# print("Enemy is_dashing: ", enemy.is_dashing)
	# print("Enemy current_stance: ", Enemy.Stance.keys()[enemy.current_stance])
	
	# Check for player hits using the actual attack area collision
	var bodies = enemy.attack_area.get_overlapping_bodies()
	# print("Bodies found in attack_area: ", bodies.size())
	
	if bodies.size() == 0:
		# print("DEBUG: NO BODIES FOUND - Attack area empty!")
		# Additional debug: Check if attack_area exists and is configured
		if not enemy.attack_area:
			# print("ERROR: attack_area is null!")
			pass
		else:
			# print("Attack area exists, checking collision shape...")
			var attack_collision = enemy.attack_area.get_child(0) as CollisionShape2D
			if not attack_collision:
				# print("ERROR: No collision shape found in attack_area!")
				pass
			elif not attack_collision.shape:
				# print("ERROR: Collision shape is null!")
				pass
			else:
				var shape = attack_collision.shape as CircleShape2D
				if shape:
					var effective_radius = shape.radius * attack_collision.scale.x
					# print("Attack collision shape radius: ", shape.radius)
					# print("Attack collision scale: ", attack_collision.scale)
					# print("Effective attack radius: ", effective_radius, "px")
					# print("Attack collision position: ", attack_collision.global_position)
					pass
				else:
					# print("ERROR: Shape is not CircleShape2D!")
					pass
	else:
		# print("Bodies found:")
		for i in range(bodies.size()):
			var body = bodies[i]
			# print("  [", i, "] ", body.name, " (", body.get_class(), ") at ", body.global_position)
			# print("      Distance to enemy: ", enemy.global_position.distance_to(body.global_position))
			pass
	
	# Check if player exists in scene
	var player_ref = enemy.get_tree().get_first_node_in_group("player")
	if player_ref:
		var distance_to_player = enemy.global_position.distance_to(player_ref.global_position)
		print("Player found in scene at: ", player_ref.global_position)
		print("Distance to player: ", distance_to_player, "px")
		print("Player collision layers: ", player_ref.collision_layer)
		print("Player collision mask: ", player_ref.collision_mask)
		print("Enemy collision layers: ", enemy.collision_layer)
		print("Enemy collision mask: ", enemy.collision_mask)
		print("Attack area collision layers: ", enemy.attack_area.collision_layer)
		print("Attack area collision mask: ", enemy.attack_area.collision_mask)
	else:
		print("ERROR: No player found in scene!")
	
	print("Players already hit this dash: ", enemy.players_hit_this_dash.size())
	# Attack collision processing complete
	
	for body in bodies:
		if body is Player and not body in enemy.players_hit_this_dash:
			# Detect combat scenario: mutual attack or attack vs defense
			var is_mutual_attack = enemy.detect_mutual_attack_with_body(body)
			# Calculate combat result based on stance matchup and scenario
			var combat_result = enemy.calculate_combat_damage(enemy.current_stance, body.current_stance, is_mutual_attack)
			
			# Handle defense point consumption
			if combat_result.player_defense_consumed:
				if body.has_method("consume_defense_point"):
					if body.consume_defense_point():
						print("Player blocked with defense point!")
						# Play regular block sound (successful block outside parry window)
						if body.audio_manager and body.walking_audio:
							body.audio_manager.play_regular_block_sfx(body.walking_audio)
					else:
						# No defense points left, take damage instead (reduced for same-stance balance)
						combat_result.damage = 1
						body.take_damage(combat_result.damage)
				else:
					# Fallback if method doesn't exist
					body.take_damage(combat_result.damage)
			elif combat_result.damage > 0:
				# V2: Handle weak stance damage absorption
				if combat_result.weak_stance_damage and body.has_method("consume_multiple_defense_points"):
					# Try to absorb weak stance damage with defense points
					var absorbed_damage = body.consume_multiple_defense_points(combat_result.damage)
					var remaining_damage = combat_result.damage - absorbed_damage
					if absorbed_damage > 0:
						print("Defense points absorbed ", absorbed_damage, " damage from weak stance!")
					if remaining_damage > 0:
						body.take_damage(remaining_damage)
				else:
					# Regular damage application
					body.take_damage(combat_result.damage)
			
			# Handle enemy stun (parry success!)
			if combat_result.enemy_stunned:
				enemy.apply_stun()
			
			# Add player to the list of already hit players
			enemy.players_hit_this_dash.append(body)
			print("Enemy attack result: ", combat_result.damage, " damage (mutual: ", is_mutual_attack, ")")