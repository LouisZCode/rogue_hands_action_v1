extends Node
class_name AudioManager

# Audio management for the game
# Load audio resources
@export var walking_sound: AudioStream = preload("res://assets/sfx/player_walking_base_sfx_01.mp3")

# Combat SFX
@export var perfect_parry_sfx: AudioStream = preload("res://assets/sfx/perfect_parry_sfx.mp3")
@export var regular_block_sfx: AudioStream = preload("res://assets/sfx/player_hit_heavy_sfx.mp3")
@export var player_attack_sfx: AudioStream = preload("res://assets/sfx/player_attack_sfx.mp3")
@export var enemy_attack_sfx: AudioStream = preload("res://assets/sfx/player_attack_sfx.mp3")
@export var player_hit_sfx: AudioStream = preload("res://assets/sfx/player_hit_sfx.mp3")
@export var enemy_hit_sfx: AudioStream = preload("res://assets/sfx/enemy_hit_sfx.mp3")

# Status Effect SFX
@export var player_stun_sfx: AudioStream = preload("res://assets/sfx/player_stun_sfx.mp3")
@export var enemy_stun_sfx: AudioStream = preload("res://assets/sfx/enemy_stun_sfx.mp3")
@export var defense_point_consumed_sfx: AudioStream = preload("res://assets/sfx/defense_point_consumed_sfx.mp3")

# Stance Change SFX
@export var player_stance_rock_sfx: AudioStream = preload("res://assets/sfx/player_stance_rock_sfx.mp3")
@export var player_stance_paper_sfx: AudioStream = preload("res://assets/sfx/player_stance_paper_sfx.mp3")
@export var player_stance_scissor_sfx: AudioStream = preload("res://assets/sfx/player_stance_scissor_sfx.mp3")

# Game State SFX
@export var player_death_sfx: AudioStream
@export var enemy_death_sfx: AudioStream = preload("res://assets/sfx/enemy_death_sfx.mp3")

func _ready():
	print("AudioManager initialized - ready for sound effects")

func play_walking_sound(audio_player: AudioStreamPlayer2D):
	if audio_player and not audio_player.playing:
		audio_player.stream = walking_sound
		audio_player.play()
		# print("Walking sound started")

func stop_walking_sound(audio_player: AudioStreamPlayer2D):
	if audio_player and audio_player.playing:
		audio_player.stop()
		# print("Walking sound stopped")

# Combat SFX Functions
func play_perfect_parry_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and perfect_parry_sfx:
		audio_player.stream = perfect_parry_sfx
		audio_player.play()

func play_regular_block_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and regular_block_sfx:
		audio_player.stream = regular_block_sfx
		audio_player.play()

func play_player_attack_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and player_attack_sfx:
		audio_player.stream = player_attack_sfx
		audio_player.play()

func play_enemy_attack_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and enemy_attack_sfx:
		audio_player.stream = enemy_attack_sfx
		audio_player.play()

func play_player_hit_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and player_hit_sfx:
		audio_player.stream = player_hit_sfx
		audio_player.play()

func play_enemy_hit_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and enemy_hit_sfx:
		audio_player.stream = enemy_hit_sfx
		audio_player.play()

# Status Effect SFX Functions
func play_player_stun_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and player_stun_sfx:
		audio_player.stream = player_stun_sfx
		audio_player.play()

func play_enemy_stun_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and enemy_stun_sfx:
		audio_player.stream = enemy_stun_sfx
		audio_player.play()

func play_player_stance_rock_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and player_stance_rock_sfx:
		audio_player.stream = player_stance_rock_sfx
		audio_player.pitch_scale = 1.0  # Normal speed for rock sound
		audio_player.play()

func play_player_stance_paper_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and player_stance_paper_sfx:
		audio_player.stream = player_stance_paper_sfx
		audio_player.pitch_scale = 1.0  # Normal speed for paper sound
		audio_player.play()

func play_player_stance_scissor_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and player_stance_scissor_sfx:
		audio_player.stream = player_stance_scissor_sfx
		audio_player.pitch_scale = 2.0  # Double speed for scissor sound
		audio_player.play()

func play_defense_point_consumed_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and defense_point_consumed_sfx:
		audio_player.stream = defense_point_consumed_sfx
		audio_player.play()

# Game State SFX Functions
func play_player_death_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and player_death_sfx:
		audio_player.stream = player_death_sfx
		audio_player.play()

func play_enemy_death_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and enemy_death_sfx:
		audio_player.stream = enemy_death_sfx
		audio_player.play()