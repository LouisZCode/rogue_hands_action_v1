class_name EnemyDatabaseManager
extends Node

## Enemy Database Manager
## Handles Excel/CSV integration and provides tools for enemy resource management
## Call these functions from GameManager or use as development tools

func _ready():
	# Check if .tres files exist, if not regenerate from CSV
	if not check_tres_files_exist():
		print("⚠️ Missing .tres files detected - attempting recovery from CSV...")
		regenerate_from_existing_csv()
	else:
		# Export current resources to CSV on startup for initial database creation
		export_enemies_to_csv()

func export_enemies_to_csv():
	"""Export current enemy resources to CSV for Excel editing"""
	print("=== EXPORTING ENEMY DATABASE ===")
	
	var success = EnemyResourceGenerator.export_current_resources_to_csv(
		"res://Resources/Enemies/", 
		"res://Resources/Enemies/enemy_database.csv"
	)
	
	if success:
		print("✅ Enemy database exported to: res://Resources/Enemies/enemy_database.csv")
		print("📝 You can now edit this file in Excel and reimport with update_from_csv()")
	else:
		print("❌ Failed to export enemy database")

func update_from_csv(csv_path: String = "res://Resources/Enemies/enemy_database.csv"):
	"""Update enemy resources from edited CSV file"""
	print("=== UPDATING FROM CSV DATABASE ===")
	
	# Validate CSV format first
	var validation = EnemyResourceGenerator.validate_csv_format(csv_path)
	if not validation.valid:
		print("❌ CSV Validation Failed:")
		for error in validation.errors:
			print("  ERROR: ", error)
		for warning in validation.warnings:
			print("  WARNING: ", warning)
		return false
	
	print("✅ CSV Validation Passed - ", validation.valid_rows, " valid rows found")
	
	# Generate new resources
	var created_files = EnemyResourceGenerator.generate_resources_from_csv(csv_path, "res://Resources/Enemies/")
	
	if created_files.size() > 0:
		print("✅ Successfully updated ", created_files.size(), " enemy resources:")
		for file_path in created_files:
			print("  📄 ", file_path)
		
		# Reload resources in GameManager if available
		reload_game_resources()
		return true
	else:
		print("❌ No resources were created from CSV")
		return false

func reload_game_resources():
	"""Notify GameManager to reload enemy resources"""
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("refresh_enemy_resources"):
		game_manager.refresh_enemy_resources()
		print("🔄 Reloaded resources in GameManager")

func create_test_database():
	"""Create a test CSV with example enemy data for demonstration"""
	print("=== CREATING TEST DATABASE ===")
	
	var csv_content = """enemy_name,max_health,max_defense_points,speed,dash_speed,dash_duration,instant_detection,detection_radius,detection_range,enhanced_detection_radius,vision_angle,vision_range,vision_collision_mask,sprite_texture_path,sprite_scale,color_tint,attack_cooldown,attack_range,damage_multiplier,stun_duration,neutral_probability,rock_probability,paper_probability,scissors_probability,stance_to_dash_delay,stance_decision_timer,positioning_timer_min,positioning_timer_max,retreat_timer,aggression_level,can_react,reaction_chance,reaction_time,body_collision_size,attack_radius,attack_collision_scale
TestTankEnemy,10,3,60,200,1.0,true,400,150,300,90,200,2,res://assets/test_sprites/rock_enemy.png,0.28|0.28,0.7|0.2|0.2|1,2.0,120,1.5,3.0,10,60,20,10,1.5,0.5,1.0,2.0,0.5,0.6,false,0.5,1.0,35|28,35,1.3|1.3
TestSpeedEnemy,2,1,180,500,0.3,true,700,150,300,70,180,2,res://assets/test_sprites/scissor_enemy.png,0.15|0.15,1.2|0.8|0.1|1,0.6,60,0.8,3.0,5,10,15,70,0.4,0.1,1.0,2.0,0.3,2.0,true,0.8,0.5,18|14,18,0.7|0.7
TestMageEnemy,4,2,90,280,0.7,false,500,150,350,110,250,2,res://assets/test_sprites/paper_enemy.png,0.20|0.20,0.3|0.5|1.0|1,1.4,110,1.2,3.0,30,15,40,15,1.1,0.25,1.0,2.0,1.2,1.3,true,0.7,0.8,24|20,28,1.1|1.1"""
	
	var file = FileAccess.open("res://test_enemy_database.csv", FileAccess.WRITE)
	if file:
		file.store_string(csv_content)
		file.close()
		print("✅ Created test database: res://test_enemy_database.csv")
		print("📝 Use update_from_csv('res://test_enemy_database.csv') to import test enemies")
		return true
	else:
		print("❌ Failed to create test database")
		return false

func get_database_stats():
	"""Print statistics about current enemy database"""
	print("=== ENEMY DATABASE STATISTICS ===")
	
	var dir = DirAccess.open("res://Resources/Enemies/")
	if not dir:
		print("❌ Cannot access resources folder")
		return
	
	var enemy_count = 0
	var enemy_types = {}
	var health_range = {"min": 999, "max": 0}
	var speed_range = {"min": 999.0, "max": 0.0}
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var enemy_data = load("res://Resources/Enemies/" + file_name) as EnemyData
			if enemy_data:
				enemy_count += 1
				
				# Track archetype
				var archetype = enemy_data.get_archetype_description()
				if not enemy_types.has(archetype):
					enemy_types[archetype] = 0
				enemy_types[archetype] += 1
				
				# Track stat ranges
				health_range.min = min(health_range.min, enemy_data.max_health)
				health_range.max = max(health_range.max, enemy_data.max_health)
				speed_range.min = min(speed_range.min, enemy_data.speed)
				speed_range.max = max(speed_range.max, enemy_data.speed)
		
		file_name = dir.get_next()
	
	print("📊 Total Enemies: ", enemy_count)
	print("🏷️ Archetypes:")
	for archetype in enemy_types:
		print("  ", archetype, ": ", enemy_types[archetype])
	print("❤️ Health Range: ", health_range.min, " - ", health_range.max)
	print("🏃 Speed Range: ", speed_range.min, " - ", speed_range.max)

func check_tres_files_exist() -> bool:
	"""Check if any .tres files exist in the enemies folder"""
	var dir = DirAccess.open("res://Resources/Enemies/")
	if not dir:
		return false
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			return true
		file_name = dir.get_next()
	
	return false

func regenerate_from_existing_csv():
	"""Try to regenerate .tres files from available CSV data"""
	var csv_files = ["enemy_database_improved.csv", "enemy_database.csv"]
	
	for csv_file in csv_files:
		var csv_path = "res://Resources/Enemies/" + csv_file
		if FileAccess.file_exists(csv_path):
			print("📄 Found CSV file: ", csv_file)
			if update_from_csv(csv_path):
				print("✅ Successfully regenerated .tres files from ", csv_file)
				return
	
	print("❌ No valid CSV files found for regeneration")

# Development helper functions for quick testing
func _input(event):
	# Only respond to debug inputs in development
	if OS.is_debug_build():
		if event.is_action_pressed("ui_page_up"):  # Page Up key
			print("🔄 Exporting current enemies to CSV...")
			export_enemies_to_csv()
		elif event.is_action_pressed("ui_page_down"):  # Page Down key
			print("📊 Getting database statistics...")
			get_database_stats()
		elif event.is_action_pressed("ui_home"):  # Home key  
			print("🧪 Creating test database...")
			create_test_database()