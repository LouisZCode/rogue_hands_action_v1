extends Node
class_name AudioManager

# Audio management for the game
# Load audio resources
@export var walking_sound: AudioStream = preload("res://assets/sfx/player_walking_base_sfx_01.mp3")

func _ready():
	print("AudioManager initialized - ready for sound effects")

func play_walking_sound(audio_player: AudioStreamPlayer2D):
	if audio_player and not audio_player.playing:
		audio_player.stream = walking_sound
		audio_player.play()
		print("Walking sound started")

func stop_walking_sound(audio_player: AudioStreamPlayer2D):
	if audio_player and audio_player.playing:
		audio_player.stop()
		print("Walking sound stopped")

func play_attack_sound():
	print("Attack sound played")

func play_hit_sound():
	print("Hit sound played")

func play_stance_change_sound():
	print("Stance change sound played")

func play_enemy_death_sound():
	print("Enemy death sound played")

func play_player_death_sound():
	print("Player death sound played")