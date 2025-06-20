extends Control
class_name ParryCircle

var circle_color: Color = Color(0, 1, 0, 0.5)  # Semi-transparent green
var circle_radius: float = 45.0  # Radius in pixels

func _draw():
	if visible:
		# Draw circle at center of the control (50, 50 for a 100x100 control)
		draw_circle(Vector2(50, 50), circle_radius, circle_color)

func update_parry_visual(time_ratio: float):
	# Update transparency based on remaining time (fade out as time runs out)
	circle_color.a = time_ratio * 0.5  # Max alpha of 0.5, fades to 0
	
	# Update radius based on remaining time (shrink as time runs out)
	circle_radius = 30.0 + (time_ratio * 20.0)  # Scale from 30 to 50 pixels
	
	# Trigger a redraw with new values
	queue_redraw()

func show_parry_circle():
	# Reset to full visibility and size
	circle_color = Color(0, 1, 0, 0.5)
	circle_radius = 45.0
	visible = true
	queue_redraw()

func hide_parry_circle():
	# Hide the circle
	visible = false

func show_perfect_parry_flash():
	# Flash bright white/gold for perfect parry feedback
	circle_color = Color(1, 1, 0, 0.8)  # Bright gold
	circle_radius = 60.0  # Larger radius for emphasis
	visible = true
	queue_redraw()
	
	# Create tween to fade back to normal
	var flash_tween = create_tween()
	flash_tween.tween_method(flash_fade_callback, 1.0, 0.0, 0.5)
	flash_tween.tween_callback(hide_parry_circle)

func flash_fade_callback(fade_ratio: float):
	# Called during flash fade animation
	circle_color = Color(1, 1, 0, fade_ratio * 0.8)  # Fade out gold
	circle_radius = 60.0 - (fade_ratio * 10.0)  # Shrink slightly
	queue_redraw()