extends Node

@export var BGM : AudioStream
@export var stage_clear_sfx : AudioStream
@export var enemy_death_sfx : AudioStream
@export var player_shoot_sfx : AudioStream
@export var enemy_shoot_sfx : AudioStream
@export var player_hurt_sfx : AudioStream
@export var cover_hit_sfx : AudioStream
var bgm : AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	bgm = AudioStreamPlayer.new()
	bgm.stream = BGM
	bgm.volume_db = -9.0
	add_child(bgm)

func playBGM():
	if !bgm.playing:
		bgm.play()
	
func stopBGM():
	bgm.stop()
	
func playSE(stream : AudioStream, vol_change : float = 0.0, pitch_scale : float = 1.0):
	var audio = AudioStreamPlayer.new()
	
	if stream == stage_clear_sfx:
		bgm.stream_paused = true
		audio.finished.connect( func resume(): bgm.stream_paused = false )

	audio.stream = stream
	audio.volume_db = vol_change
	audio.pitch_scale = pitch_scale
	add_child(audio)
	audio.play()
	audio.finished.connect(audio.queue_free)

func stop_victory_audio():
	for audio in get_children():
		if audio.stream == stage_clear_sfx:
			audio.stop()
			audio.queue_free()
			bgm.set_stream_paused(false)

func _on_main_play_audio_player_shot():
	playSE(player_shoot_sfx, -12.0, 1.2)

func _on_main_play_audio_stage_clear():
	playSE(stage_clear_sfx, -9.0)

func _on_enemies_play_audio_enemy_death():
	playSE(enemy_death_sfx, -9.0, randf_range(0.6, 1.6))

func _on_enemies_play_audio_enemy_shot():
	playSE(enemy_shoot_sfx, -16.0, 0.7)

func _on_player_play_audio_player_hurt():
	playSE(player_hurt_sfx, 12.0, 0.7)
	
func on_cover_hit():
	playSE(cover_hit_sfx, -14.0, 0.7)
