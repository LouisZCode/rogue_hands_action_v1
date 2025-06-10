extends Node2D
class_name CombatFeedback

# Visual feedback for combat results
@onready var label: Label = $Label

func _ready():
	# Create label if it doesn't exist
	if not has_node("Label"):
		label = Label.new()
		add_child(label)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func show_combat_result(result: String, damage: int, pos: Vector2):
	global_position = pos
	
	if label:
		label.text = result + "\n-" + str(damage)
		
		# Color based on result
		match result:
			"PLAYER WINS":
				label.modulate = Color.GREEN
			"ENEMY WINS":
				label.modulate = Color.RED
			"TIE":
				label.modulate = Color.YELLOW
		
		# Animate the feedback
		var tween = create_tween()
		tween.parallel().tween_property(self, "position", position + Vector2(0, -50), 1.0)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)