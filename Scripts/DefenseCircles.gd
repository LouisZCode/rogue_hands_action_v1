extends Control
class_name DefenseCircles

var circle_color: Color = Color(0, 0.7, 1, 0.3)  # Semi-transparent blue
var circle_spacing: float = 5.0  # Space between circles
var base_radius: float = 18.0  # Starting radius for innermost circle
var current_defense_points: int = 3
var max_defense_points: int = 3

# Animation variables for fading circles
var fading_circles: Array[Dictionary] = []  # Store fading circle data

func _draw():
	if visible:
		# Draw current defense point circles
		for i in range(current_defense_points):
			var radius = base_radius + (i * circle_spacing)
			draw_circle(Vector2(50, 50), radius, circle_color)  # Center at (50,50) for 100x100 control
		
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
	visible = true
	queue_redraw()

func hide_defense_circles():
	visible = false