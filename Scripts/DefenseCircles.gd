extends Control
class_name DefenseCircles

var circle_color: Color = Color(0, 0.7, 1, 0.3)  # Semi-transparent blue
var circle_spacing: float = 5.0  # Space between circles
var base_radius: float = 18.0  # Starting radius for innermost circle
var current_defense_points: int = 3
var max_defense_points: int = 3

# Animation variables for fading circles
var fading_circles: Array[Dictionary] = []  # Store fading circle data

# Debug state tracking
var should_be_visible: bool = false
var debug_enabled: bool = false

func _draw():
	if visible:
		# Draw current defense point circles
		for i in range(current_defense_points):
			var radius = base_radius + (i * circle_spacing)
			draw_circle(Vector2(50, 50), radius, circle_color)  # Center of control
		
		# Draw fading circles (expansion animation)
		for fade_data in fading_circles:
			var fade_radius = fade_data.radius
			var fade_alpha = fade_data.alpha
			var fade_color = Color(0, 0.7, 1, fade_alpha)
			draw_circle(Vector2(50, 50), fade_radius, fade_color)

func update_defense_points(new_defense_points: int):
	if new_defense_points < current_defense_points:
		# Defense point was consumed - trigger fade animation
		trigger_fade_animation()
	
	current_defense_points = new_defense_points
	queue_redraw()

func trigger_fade_animation():
	# Create fading circle for the lost defense point
	var lost_circle_index = current_defense_points - 1  # Index of circle being lost
	var fade_radius = base_radius + (lost_circle_index * circle_spacing)
	
	var fade_data = {
		"radius": fade_radius,
		"alpha": 0.5,  # Starting alpha
		"target_radius": fade_radius + 30.0,  # Expand by 30px
		"fade_duration": 0.5
	}
	
	fading_circles.append(fade_data)
	
	# Create tween for the fade animation
	var fade_tween = create_tween()
	fade_tween.parallel().tween_method(update_fade_circle.bind(fade_data), 0.0, 1.0, 0.5)
	fade_tween.tween_callback(remove_fade_circle.bind(fade_data))

func update_fade_circle(fade_data: Dictionary, progress: float):
	# Update the fading circle's properties
	fade_data.radius = lerp(fade_data.radius, fade_data.target_radius, progress)
	fade_data.alpha = lerp(0.5, 0.0, progress)  # Fade from 0.5 to 0
	queue_redraw()

func remove_fade_circle(fade_data: Dictionary):
	# Remove the fading circle from the array
	fading_circles.erase(fade_data)
	queue_redraw()

func show_defense_circles():
	should_be_visible = true
	visible = true
	if debug_enabled:
		print("DEBUG: DefenseCircles.show_defense_circles() called - visible=", visible, " should_be_visible=", should_be_visible)
	queue_redraw()

func hide_defense_circles():
	should_be_visible = false
	visible = false
	if debug_enabled:
		print("DEBUG: DefenseCircles.hide_defense_circles() called - visible=", visible, " should_be_visible=", should_be_visible)

func _ready():
	# Initialize debug state
	should_be_visible = false
	visible = false
	if debug_enabled:
		print("DEBUG: DefenseCircles._ready() - initialized as hidden")

func validate_visibility_state(player_stance_name: String):
	# Safety check to ensure visibility matches expected state
	var is_combat_stance = (player_stance_name != "NEUTRAL")
	
	if is_combat_stance and not should_be_visible:
		if debug_enabled:
			print("DEBUG: MISMATCH - In combat stance (", player_stance_name, ") but circles should not be visible!")
		show_defense_circles()
	elif not is_combat_stance and should_be_visible:
		if debug_enabled:
			print("DEBUG: MISMATCH - In neutral stance but circles should be visible!")
		hide_defense_circles()
	
	# Additional check for visibility vs should_be_visible mismatch
	if visible != should_be_visible:
		if debug_enabled:
			print("DEBUG: VISIBILITY MISMATCH - visible=", visible, " should_be_visible=", should_be_visible, " stance=", player_stance_name)
		visible = should_be_visible