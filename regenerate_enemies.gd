extends Node

# Simple script to regenerate enemy .tres files from updated CSV
func _ready():
	print("=== REGENERATING ENEMY RESOURCES ===")
	
	# Create database manager instance
	var db_manager = preload("res://Scripts/EnemyDatabaseManager.gd").new()
	
	# Regenerate from the improved CSV with updated scale values
	var success = db_manager.update_from_csv("res://Resources/Enemies/enemy_database_improved.csv")
	
	if success:
		print("✅ Successfully regenerated enemy resources with new scale values!")
		print("🎯 Enemies should now be properly sized")
	else:
		print("❌ Failed to regenerate enemy resources")
	
	# Exit after regeneration
	get_tree().quit()