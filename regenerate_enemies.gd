extends Node

# Simple script to regenerate enemy .tres files from updated CSV
func _ready():
	print("=== REGENERATING ENEMY RESOURCES ===")
	
	# Check if CSV file exists
	var csv_path = "res://Resources/Enemies/enemy_database_improved.csv"
	if not FileAccess.file_exists(csv_path):
		print("❌ CSV file not found at: ", csv_path)
		get_tree().quit()
		return
	
	print("📄 Found CSV file at: ", csv_path)
	
	# Read first few lines to verify content
	var file = FileAccess.open(csv_path, FileAccess.READ)
	if file:
		print("📋 CSV Header: ", file.get_line())
		print("📋 First Row: ", file.get_line())
		file.close()
	
	# Create database manager instance
	var db_manager = preload("res://Scripts/EnemyDatabaseManager.gd").new()
	
	# Check existing .tres file before regeneration
	var basic_enemy_path = "res://Resources/Enemies/BasicBalancedEnemy.tres"
	if FileAccess.file_exists(basic_enemy_path):
		var existing_enemy = load(basic_enemy_path) as EnemyData
		if existing_enemy:
			print("🔍 BEFORE: BasicBalancedEnemy scale = ", existing_enemy.sprite_scale)
	
	# Regenerate from the improved CSV with updated scale values
	print("🔄 Calling update_from_csv...")
	var success = db_manager.update_from_csv(csv_path)
	
	# Check .tres file after regeneration
	if FileAccess.file_exists(basic_enemy_path):
		var new_enemy = load(basic_enemy_path) as EnemyData
		if new_enemy:
			print("🔍 AFTER: BasicBalancedEnemy scale = ", new_enemy.sprite_scale)
	
	if success:
		print("✅ Successfully regenerated enemy resources with new scale values!")
		print("🎯 Enemies should now be properly sized")
	else:
		print("❌ Failed to regenerate enemy resources")
	
	# Wait a moment before exiting
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()