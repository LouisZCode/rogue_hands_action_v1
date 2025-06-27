extends RefCounted
class_name CombatCalculator

# Centralized combat calculation system
# Handles all rock-paper-scissors combat logic in one place
# Uses int stance values: 0=NEUTRAL, 1=ROCK, 2=PAPER, 3=SCISSORS

# Combat result structure
static func create_combat_result() -> Dictionary:
	return {
		"damage": 0,
		"attacker_stunned": false,
		"defender_defense_consumed": false,
		"weak_stance_damage": false,
		"is_tie": false,
		"result_description": ""
	}

# Main combat resolution function
static func resolve_combat(attacker_stance: int, defender_stance: int, is_mutual_attack: bool = false) -> Dictionary:
	var result = create_combat_result()
	
	# Mutual attack scenario (both players dashing)
	if is_mutual_attack:
		result = resolve_mutual_attack(attacker_stance, defender_stance)
	else:
		# Attack vs Defense scenario
		result = resolve_attack_vs_defense(attacker_stance, defender_stance)
	
	return result

# Handle mutual attack scenarios (both players dashing)
static func resolve_mutual_attack(attacker_stance: int, defender_stance: int) -> Dictionary:
	var result = create_combat_result()
	
	if attacker_stance == defender_stance:
		# Tie - no damage to either
		result.damage = 0
		result.is_tie = true
		result.result_description = "MUTUAL TIE - No damage"
	elif is_stance_winning(attacker_stance, defender_stance):
		# Attacker wins - defender takes damage
		result.damage = GameConstants.MUTUAL_ATTACK_DAMAGE
		result.result_description = "MUTUAL WIN - " + get_stance_name(attacker_stance) + " beats " + get_stance_name(defender_stance)
	else:
		# Attacker loses - attacker gets stunned, no damage to defender
		result.damage = 0
		result.attacker_stunned = true
		result.result_description = "MUTUAL LOSS - Attacker stunned by " + get_stance_name(defender_stance)
	
	return result

# Handle attack vs defense scenarios (one attacking, one defending)
static func resolve_attack_vs_defense(attacker_stance: int, defender_stance: int) -> Dictionary:
	var result = create_combat_result()
	
	if defender_stance == 0:  # NEUTRAL
		# Neutral stance takes reduced damage
		result.damage = GameConstants.NEUTRAL_STANCE_DAMAGE
		result.result_description = "vs NEUTRAL - " + str(result.damage) + " damage"
	elif attacker_stance == defender_stance:
		# Same stance - perfect block, consumes defense point
		result.damage = 0
		result.defender_defense_consumed = true
		result.result_description = "PERFECT BLOCK - Same stance defense"
	elif is_stance_winning(attacker_stance, defender_stance):
		# Attacker wins against weak stance
		result.damage = GameConstants.WEAK_STANCE_DAMAGE
		result.weak_stance_damage = true
		result.result_description = "WEAK STANCE - " + get_stance_name(attacker_stance) + " beats " + get_stance_name(defender_stance)
	else:
		# Attacker loses against strong stance - potential perfect parry
		result.damage = 0
		result.result_description = "STRONG STANCE - " + get_stance_name(defender_stance) + " blocks " + get_stance_name(attacker_stance)
	
	return result

# Rock-paper-scissors logic: check if attacker_stance beats defender_stance
static func is_stance_winning(attacker_stance: int, defender_stance: int) -> bool:
	return (attacker_stance == 1 and defender_stance == 3) or \
		   (attacker_stance == 2 and defender_stance == 1) or \
		   (attacker_stance == 3 and defender_stance == 2)

# Helper function to get stance effectiveness description
static func get_stance_matchup_description(attacker_stance: int, defender_stance: int) -> String:
	if attacker_stance == defender_stance:
		return "EQUAL"
	elif is_stance_winning(attacker_stance, defender_stance):
		return "ADVANTAGE"
	else:
		return "DISADVANTAGE"

# Calculate damage with multipliers (for enemy data variations)
static func calculate_damage_with_multiplier(base_damage: int, multiplier: float) -> int:
	return max(1, int(base_damage * multiplier))

# Helper function to convert int stance to string name
static func get_stance_name(stance: int) -> String:
	match stance:
		0: return "NEUTRAL"
		1: return "ROCK"
		2: return "PAPER"
		3: return "SCISSORS"
		_: return "UNKNOWN"