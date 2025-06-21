extends Line2D
class_name DashPreview

# Dash trajectory visualization for both player and enemy
#
# Z-INDEX ARCHITECTURE FOR PROJECT:
# 10+ : UI elements, floating text, damage numbers
# 5-9 : Above-character effects (floating particles, status icons)
# 2-4 : Character sprites and important game objects
# 0-1 : Below-character gameplay elements (lines, circles, decals, auras)
# -5-(-1): Background decorative elements
# -10-(-6): Base background, terrain
@export var dash_line_color: Color = Color.BLUE
@export var dash_line_width: float = 40.0
@export var dash_line_alpha: float = 0.5

# Configuration - now dynamic, no hardcoded values

func _ready():
	# Configure line appearance
	default_color = dash_line_color
	width = dash_line_width
	default_color.a = dash_line_alpha
	
	# Z-Index Architecture: Below character sprites (z=2) but above background (z<0)
	z_index = 0
	
	# Hide by default
	visible = false

func show_simple_dash_line(relative_end: Vector2):
	# Simple line from character center (0,0) to relative end position
	# Since Line2D is child of character, (0,0) is character center
	clear_points()
	add_point(Vector2.ZERO)  # Start at character center
	add_point(relative_end)  # End at relative position from character
	visible = true

# Legacy function for backward compatibility
func show_dash_trajectory(start_pos: Vector2, direction: Vector2, speed: float, duration: float):
	var dash_distance = speed * duration
	var relative_end = direction.normalized() * dash_distance
	show_simple_dash_line(relative_end)

func hide_dash_trajectory():
	visible = false
	clear_points()

func clamp_to_level_bounds(pos: Vector2) -> Vector2:
	# Basic level boundary clamping (adjust based on your level size)
	var level_bounds = Rect2(-400, -250, 800, 500)  # Updated scene bounds
	return Vector2(
		clamp(pos.x, level_bounds.position.x + 25, level_bounds.position.x + level_bounds.size.x - 25),
		clamp(pos.y, level_bounds.position.y + 25, level_bounds.position.y + level_bounds.size.y - 25)
	)

func set_line_color(color: Color):
	dash_line_color = color
	default_color = color
	default_color.a = dash_line_alpha

func set_enemy_style():
	# Red line for enemy trajectories
	set_line_color(Color.RED)

func set_player_style():
	# Blue line for player trajectories  
	set_line_color(Color.ROYAL_BLUE)

# Simplified - use direct character positions
