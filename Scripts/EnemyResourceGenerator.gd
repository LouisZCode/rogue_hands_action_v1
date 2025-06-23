class_name EnemyResourceGenerator
extends RefCounted

## Enemy Resource Generator
## Reads enemy data from CSV/Excel files and generates .tres resource files
## Enables batch enemy creation and easy parameter management

static func generate_resources_from_csv(csv_path: String, output_folder: String = "res://Resources/Enemies/") -> Array[String]:
	"""Generate .tres files from CSV data. Returns array of created file paths."""
	var created_files: Array[String] = []
	
	# Read CSV file
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		print("ERROR: Cannot open CSV file: ", csv_path)
		return created_files
	
	# Read header row to get column names
	var header_line = file.get_line()
	if header_line == "":
		print("ERROR: Empty CSV file: ", csv_path)
		file.close()
		return created_files
	
	var headers = header_line.split(",")
	var header_map = {}
	
	# Create header index mapping
	for i in range(headers.size()):
		header_map[headers[i].strip_edges()] = i
	
	print("CSV Headers found: ", headers)
	
	# Process each data row
	var row_count = 0
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges() == "":
			continue
			
		var values = line.split(",")
		if values.size() != headers.size():
			print("WARNING: Row ", row_count + 1, " has mismatched column count. Skipping.")
			continue
		
		# Create enemy data resource
		var enemy_data = create_enemy_data_from_row(header_map, values)
		if enemy_data:
			# Generate .tres file
			var file_name = enemy_data.enemy_name.replace(" ", "") + ".tres"
			var output_path = output_folder + file_name
			
			var save_result = ResourceSaver.save(enemy_data, output_path)
			if save_result == OK:
				created_files.append(output_path)
				print("Created: ", output_path, " - ", enemy_data.enemy_name)
			else:
				print("ERROR: Failed to save resource: ", output_path)
		
		row_count += 1
	
	file.close()
	print("Generated ", created_files.size(), " enemy resources from ", row_count, " CSV rows")
	return created_files

static func create_enemy_data_from_row(header_map: Dictionary, values: Array) -> EnemyData:
	"""Create EnemyData resource from CSV row data"""
	var enemy_data = EnemyData.new()
	
	# Helper function to safely get values with defaults
	var get_value = func(column_name: String, default_value):
		if header_map.has(column_name) and header_map[column_name] < values.size():
			var raw_value = values[header_map[column_name]].strip_edges()
			if raw_value == "":
				return default_value
			
			# Type conversion based on default value type
			if default_value is String:
				return raw_value
			elif default_value is int:
				return int(raw_value) if raw_value.is_valid_int() else default_value
			elif default_value is float:
				return float(raw_value) if raw_value.is_valid_float() else default_value
			elif default_value is bool:
				return raw_value.to_lower() in ["true", "1", "yes", "on"]
			elif default_value is Vector2:
				# Handle both old format (x|y) and new format (separate columns)
				if "|" in raw_value:
					var parts = raw_value.split("|")
					if parts.size() >= 2:
						return Vector2(float(parts[0]), float(parts[1]))
				else:
					# Single value for both x and y
					return Vector2(float(raw_value), float(raw_value))
				return default_value
			elif default_value is Color:
				# Handle both old format (r|g|b|a) and new format (separate columns)
				if "|" in raw_value:
					var parts = raw_value.split("|")
					if parts.size() >= 3:
						var r = float(parts[0]) if parts[0].is_valid_float() else 1.0
						var g = float(parts[1]) if parts[1].is_valid_float() else 1.0
						var b = float(parts[2]) if parts[2].is_valid_float() else 1.0
						var a = float(parts[3]) if parts.size() > 3 and parts[3].is_valid_float() else 1.0
						return Color(r, g, b, a)
				else:
					# Single color component
					return Color(float(raw_value), float(raw_value), float(raw_value), 1.0)
				return default_value
		return default_value
	
	# Basic Stats
	enemy_data.enemy_name = get_value.call("enemy_name", "Unnamed Enemy")
	enemy_data.max_health = get_value.call("max_health", 5)
	enemy_data.max_defense_points = get_value.call("max_defense_points", 1)
	
	# Movement
	enemy_data.speed = get_value.call("speed", 100.0)
	enemy_data.dash_speed = get_value.call("dash_speed", 300.0)
	enemy_data.dash_duration = get_value.call("dash_duration", 0.6)
	
	# Detection
	enemy_data.instant_detection = get_value.call("instant_detection", false)
	enemy_data.detection_radius = get_value.call("detection_radius", 500.0)
	enemy_data.detection_range = get_value.call("detection_range", 150.0)
	enemy_data.enhanced_detection_radius = get_value.call("enhanced_detection_radius", 300.0)
	enemy_data.vision_angle = get_value.call("vision_angle", 90.0)
	enemy_data.vision_range = get_value.call("vision_range", 200.0)
	enemy_data.vision_collision_mask = get_value.call("vision_collision_mask", 2)
	
	# Visual - Handle both old and new CSV formats
	enemy_data.sprite_texture_path = get_value.call("sprite_texture_path", "res://assets/test_sprites/idle_enemy.png")
	
	# Try new format first (separate columns), fallback to old format
	if header_map.has("sprite_scale_x") and header_map.has("sprite_scale_y"):
		var scale_x = get_value.call("sprite_scale_x", 0.21)
		var scale_y = get_value.call("sprite_scale_y", 0.21)
		enemy_data.sprite_scale = Vector2(scale_x, scale_y)
	else:
		enemy_data.sprite_scale = get_value.call("sprite_scale", Vector2(0.21, 0.21))
	
	# Try new format first (separate columns), fallback to old format
	if header_map.has("color_red") and header_map.has("color_green") and header_map.has("color_blue"):
		var r = get_value.call("color_red", 1.0)
		var g = get_value.call("color_green", 1.0)
		var b = get_value.call("color_blue", 1.0)
		var a = get_value.call("color_alpha", 1.0)
		enemy_data.color_tint = Color(r, g, b, a)
	else:
		enemy_data.color_tint = get_value.call("color_tint", Color.WHITE)
	
	# Combat
	enemy_data.attack_cooldown = get_value.call("attack_cooldown", 1.2)
	enemy_data.attack_range = get_value.call("attack_range", 100.0)
	enemy_data.damage_multiplier = get_value.call("damage_multiplier", 1.0)
	enemy_data.stun_duration = get_value.call("stun_duration", 3.0)
	
	# Stance Behavior
	enemy_data.neutral_probability = get_value.call("neutral_probability", 25.0)
	enemy_data.rock_probability = get_value.call("rock_probability", 25.0)
	enemy_data.paper_probability = get_value.call("paper_probability", 25.0)
	enemy_data.scissors_probability = get_value.call("scissors_probability", 25.0)
	
	# AI Timing
	enemy_data.stance_to_dash_delay = get_value.call("stance_to_dash_delay", 1.0)
	enemy_data.stance_decision_timer = get_value.call("stance_decision_timer", 0.3)
	enemy_data.positioning_timer_min = get_value.call("positioning_timer_min", 1.0)
	enemy_data.positioning_timer_max = get_value.call("positioning_timer_max", 2.0)
	enemy_data.retreat_timer = get_value.call("retreat_timer", 1.0)
	enemy_data.aggression_level = get_value.call("aggression_level", 1.0)
	
	# Advanced AI
	enemy_data.can_react = get_value.call("can_react", false)
	enemy_data.reaction_chance = get_value.call("reaction_chance", 0.5)
	enemy_data.reaction_time = get_value.call("reaction_time", 1.0)
	enemy_data.reflex = get_value.call("reflex", 0.0)
	enemy_data.weight = get_value.call("weight", 1.0)
	
	# Collision - Handle both old and new CSV formats
	if header_map.has("body_collision_width") and header_map.has("body_collision_height"):
		var width = get_value.call("body_collision_width", 26.0)
		var height = get_value.call("body_collision_height", 21.0)
		enemy_data.body_collision_size = Vector2(width, height)
	else:
		enemy_data.body_collision_size = get_value.call("body_collision_size", Vector2(26, 21))
	
	enemy_data.attack_radius = get_value.call("attack_radius", 25.0)
	
	if header_map.has("attack_scale_x") and header_map.has("attack_scale_y"):
		var scale_x = get_value.call("attack_scale_x", 1.0)
		var scale_y = get_value.call("attack_scale_y", 1.0)
		enemy_data.attack_collision_scale = Vector2(scale_x, scale_y)
	else:
		enemy_data.attack_collision_scale = get_value.call("attack_collision_scale", Vector2(1.0, 1.0))
	
	# Validate the data
	if not enemy_data.validate_data():
		print("WARNING: Enemy data validation failed for: ", enemy_data.enemy_name)
	
	return enemy_data

static func export_current_resources_to_csv(resources_folder: String = "res://Resources/Enemies/", output_path: String = "res://Resources/Enemies/enemy_database.csv") -> bool:
	"""Export existing .tres files to CSV format for editing"""
	var output_file = FileAccess.open(output_path, FileAccess.WRITE)
	if not output_file:
		print("ERROR: Cannot create CSV file: ", output_path)
		return false
	
	# Write CSV header - User-friendly format with separate columns
	var headers = [
		"enemy_name", "max_health", "max_defense_points",
		"speed", "dash_speed", "dash_duration",
		"instant_detection", "detection_radius", "detection_range", "enhanced_detection_radius",
		"vision_angle", "vision_range", "vision_collision_mask",
		"sprite_texture_path", "sprite_scale_x", "sprite_scale_y", 
		"color_red", "color_green", "color_blue", "color_alpha",
		"attack_cooldown", "attack_range", "damage_multiplier", "stun_duration",
		"neutral_probability", "rock_probability", "paper_probability", "scissors_probability",
		"stance_to_dash_delay", "stance_decision_timer", "positioning_timer_min", "positioning_timer_max",
		"retreat_timer", "aggression_level",
		"can_react", "reaction_chance", "reaction_time", "reflex", "weight",
		"body_collision_width", "body_collision_height", "attack_radius", 
		"attack_scale_x", "attack_scale_y"
	]
	output_file.store_line(",".join(headers))
	
	# Find all .tres files in resources folder
	var dir = DirAccess.open(resources_folder)
	if not dir:
		print("ERROR: Cannot access resources folder: ", resources_folder)
		output_file.close()
		return false
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var exported_count = 0
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var resource_path = resources_folder + file_name
			var enemy_data = load(resource_path) as EnemyData
			
			if enemy_data:
				# Export to CSV row - User-friendly format with separate columns
				var row_data = [
					enemy_data.enemy_name,
					str(enemy_data.max_health),
					str(enemy_data.max_defense_points),
					str(enemy_data.speed),
					str(enemy_data.dash_speed),
					str(enemy_data.dash_duration),
					str(enemy_data.instant_detection).to_lower(),
					str(enemy_data.detection_radius),
					str(enemy_data.detection_range),
					str(enemy_data.enhanced_detection_radius),
					str(enemy_data.vision_angle),
					str(enemy_data.vision_range),
					str(enemy_data.vision_collision_mask),
					enemy_data.sprite_texture_path,
					str(enemy_data.sprite_scale.x),
					str(enemy_data.sprite_scale.y),
					str(enemy_data.color_tint.r),
					str(enemy_data.color_tint.g),
					str(enemy_data.color_tint.b),
					str(enemy_data.color_tint.a),
					str(enemy_data.attack_cooldown),
					str(enemy_data.attack_range),
					str(enemy_data.damage_multiplier),
					str(enemy_data.stun_duration),
					str(enemy_data.neutral_probability),
					str(enemy_data.rock_probability),
					str(enemy_data.paper_probability),
					str(enemy_data.scissors_probability),
					str(enemy_data.stance_to_dash_delay),
					str(enemy_data.stance_decision_timer),
					str(enemy_data.positioning_timer_min),
					str(enemy_data.positioning_timer_max),
					str(enemy_data.retreat_timer),
					str(enemy_data.aggression_level),
					str(enemy_data.can_react).to_lower(),
					str(enemy_data.reaction_chance),
					str(enemy_data.reaction_time),
					str(enemy_data.reflex),
					str(enemy_data.weight),
					str(enemy_data.body_collision_size.x),
					str(enemy_data.body_collision_size.y),
					str(enemy_data.attack_radius),
					str(enemy_data.attack_collision_scale.x),
					str(enemy_data.attack_collision_scale.y)
				]
				
				output_file.store_line(",".join(row_data))
				exported_count += 1
			else:
				print("WARNING: Failed to load resource: ", resource_path)
		
		file_name = dir.get_next()
	
	output_file.close()
	print("Exported ", exported_count, " enemy resources to CSV: ", output_path)
	return true

static func validate_csv_format(csv_path: String) -> Dictionary:
	"""Validate CSV format and return validation report"""
	var report = {
		"valid": false,
		"errors": [],
		"warnings": [],
		"row_count": 0,
		"valid_rows": 0
	}
	
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if not file:
		report.errors.append("Cannot open CSV file: " + csv_path)
		return report
	
	# Check header
	var header_line = file.get_line()
	var headers = header_line.split(",")
	
	# Required headers for basic functionality
	var required_headers = ["enemy_name", "max_health", "speed", "sprite_texture_path"]
	for req_header in required_headers:
		if not req_header in headers:
			report.errors.append("Missing required header: " + req_header)
	
	# Process rows
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges() == "":
			continue
			
		report.row_count += 1
		var values = line.split(",")
		
		if values.size() != headers.size():
			report.warnings.append("Row " + str(report.row_count) + " has mismatched column count")
		else:
			report.valid_rows += 1
	
	file.close()
	
	report.valid = report.errors.size() == 0 and report.valid_rows > 0
	return report