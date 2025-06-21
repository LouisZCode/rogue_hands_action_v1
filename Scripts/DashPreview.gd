extends Line2D
class_name DashPreview

# Dash trajectory visualization for both player and enemy
@export var dash_line_color: Color = Color.BLUE
@export var dash_line_width: float = 40.0
@export var dash_line_alpha: float = 0.5

# Configuration
var dash_speed: float = 600.0
var dash_duration: float = 0.6
var max_dash_distance: float = 360.0  # dash_speed * dash_duration

func _ready():
	# Configure line appearance
	default_color = dash_line_color
	width = dash_line_width
	default_color.a = dash_line_alpha
	
	# Ensure line renders above sprites
	z_index = 10
	
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
	var level_bounds = Rect2(-400, -300, 800, 600)  # Approximate main scene bounds
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
	set_line_color(Color.CYAN)

# Simplified - use direct character positions
