extends Node
class_name AudioManager

# Audio management for the game
# Load audio resources
@export var walking_sound: AudioStream = preload("res://assets/sfx/player_walking_base_sfx_01.mp3")

# Combat SFX
@export var perfect_parry_sfx: AudioStream = preload("res://assets/sfx/perfect_parry_sfx.mp3")
@export var regular_block_sfx: AudioStream
@export var player_attack_sfx: AudioStream
@export var enemy_attack_sfx: AudioStream
@export var player_hit_sfx: AudioStream = preload("res://assets/sfx/player_hit_sfx.mp3")
@export var enemy_hit_sfx: AudioStream

# Status Effect SFX
@export var player_stun_sfx: AudioStream = preload("res://assets/sfx/player_stun_sfx.mp3")
@export var enemy_stun_sfx: AudioStream = preload("res://assets/sfx/enemy_stun_sfx.mp3")
@export var stance_change_sfx: AudioStream
@export var defense_point_consumed_sfx: AudioStream = preload("res://assets/sfx/defense_point_consumed_sfx.mp3")

# AI/Detection SFX
@export var enemy_alert_sfx: AudioStream
@export var enemy_lost_player_sfx: AudioStream

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

func play_stance_change_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and stance_change_sfx:
		audio_player.stream = stance_change_sfx
		audio_player.play()

func play_defense_point_consumed_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and defense_point_consumed_sfx:
		audio_player.stream = defense_point_consumed_sfx
		audio_player.play()

# AI/Detection SFX Functions
func play_enemy_alert_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and enemy_alert_sfx:
		audio_player.stream = enemy_alert_sfx
		audio_player.play()

func play_enemy_lost_player_sfx(audio_player: AudioStreamPlayer2D):
	if audio_player and enemy_lost_player_sfx:
		audio_player.stream = enemy_lost_player_sfx
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