extends Node

# Script to manually fix all enemy .tres files with correct scale and texture paths
func _ready():
	print("=== FIXING ALL ENEMY .tres FILES ===")
	
	var enemy_files = [
		"BerserkerRock.tres",
		"EliteRockDestroyer.tres", 
		"LightningScissor.tres",
		"RockTankEnemy.tres",
		"ScissorScoutEnemy.tres",
		"StealthPaperAssassin.tres"
	]
	
	var scale_mappings = {
		"BerserkerRock.tres": Vector2(1.1, 1.1),
		"EliteRockDestroyer.tres": Vector2(1.1, 1.1),
		"LightningScissor.tres": Vector2(0.85, 0.85),
		"RockTankEnemy.tres": Vector2(1.1, 1.1),
		"ScissorScoutEnemy.tres": Vector2(0.85, 0.85),
		"StealthPaperAssassin.tres": Vector2(0.85, 0.85)
	}
	
	for file_name in enemy_files:
		var file_path = "res://resources/Enemies/" + file_name
		var enemy_data = load(file_path) as EnemyData
		
		if enemy_data:
			print("Updating ", file_name)
			print("  Old scale: ", enemy_data.sprite_scale)
			
			# Update scale
			enemy_data.sprite_scale = scale_mappings[file_name]
			
			# Update texture path
			enemy_data.sprite_texture_path = "res://assets/assets_game/enemy_idle.png"
			
			print("  New scale: ", enemy_data.sprite_scale)
			print("  New texture: ", enemy_data.sprite_texture_path)
			
			# Save the resource
			ResourceSaver.save(enemy_data, file_path)
			print("  ✅ Saved")
		else:
			print("❌ Failed to load ", file_name)
	
	print("✅ All enemy files updated!")
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()