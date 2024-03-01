extends Node

const SCORE_MISS := -5
const TEXT_TITLE = "SPACE INVADERS S"
const TEXT_START = "Press Space/S/Gamepad X/RB to start"
const TEXT_CONGRATULATIONS = "CONGRATULATIONS!"
const TEXT_CONTINUE = "Press Shoot for next stage"
const TEXT_GAME_OVER = "GAME OVER"
const TEXT_TRY_AGAIN = "Press Shoot to try again"
const TEXT_HIGH_SCORES = "HIGH SCORES:\n"

signal score_change_signal(change, new_score)
signal stage_change_signal(stage)
signal play_audio_player_shot
signal play_audio_stage_clear

var window_size
var player_start_pos
@export var cover_scenes = []
var is_game_running = false
var is_game_over = false
var current_score : int
var current_stage : int
var high_scores = []

# Called when the node enters the scene tree for the first time.
func _ready():
	window_size = get_viewport().get_visible_rect().size
	player_start_pos = Vector2(window_size.x / 2, window_size.y - 10)
	$Player.position = Vector2(500.0, 500.0)
	new_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("shoot") and not is_game_running:	
		if is_game_over:
			new_game()
			is_game_over = false
		else:
			new_stage()
			start_game()
	if Input.is_action_just_pressed("clear_stage") and is_game_running:
		stop_game()
		$Enemies.kill_all_enemies()
		
func new_stage():
	$Player.position = player_start_pos
	$Enemies.spawn_enemies(window_size)
	stage_change(current_stage + 1)
	spawn_covers()
	
	$UI/ScreenLabel.visible = false
	$UI/HighScoresLabel.visible = false
	$UI/LabelTimer.stop()
	$AudioManager.stop_victory_audio()
	get_tree().call_group("special_effects", "queue_free")
	
func new_game():
	current_score = 0
	score_change_signal.emit(0, current_score)
	stage_change(0)
	$Player.new_game_reset()
	$Enemies.reset_enemies()
	get_tree().call_group("cover_group", "queue_free")
	
	$UI/ScreenLabel.visible = true
	$UI/ScreenLabel.text = TEXT_TITLE
	$UI/ScreenLabel/SubLabel.text = TEXT_START
	show_game_ui(false)
	load_high_scores()	
	show_high_scores()

func show_game_ui(show : bool):
	$UI/LivesLabel.visible = show
	$UI/ScoreLabel.visible = show
	$UI/StageLabel.visible = show
	
func start_game():
	show_game_ui(true)
	is_game_running = true
	$Player.game_running = true
	$Player/ShotCooldown.start()
	$Enemies/MoveTimer.start()
	$Enemies/ShootTimer.start()
	$AudioManager.playBGM()
	
func stop_game():
	is_game_running = false
	$Player.game_running = false
	get_tree().call_group("enemy_shot", "queue_free")
	
func game_over():
	is_game_over = true
	stop_game()
	save_score()
	$AudioManager.stopBGM()
	$Player.position = Vector2(500.0, 500.0)
	$UI/ScreenLabel.visible = true
	$UI/ScreenLabel.text = TEXT_GAME_OVER
	$UI/ScreenLabel/SubLabel.text = TEXT_TRY_AGAIN
	
func stage_change(new_stage):
	current_stage = new_stage
	$Enemies.change_stage(current_stage)
	stage_change_signal.emit(current_stage)

func score_change(x):
	current_score += x
	score_change_signal.emit(x, current_score)
	
func spawn_covers():
	get_tree().call_group("cover_group", "queue_free")
	var cover_scene = cover_scenes[randi_range(0, cover_scenes.size() - 1)]
	var instance = cover_scene.instantiate()
	instance.position = Vector2.ZERO
	add_child(instance)
	
	for cover in instance.get_children():
		cover.audio_cover_hit.connect($AudioManager.on_cover_hit)

func _on_player_shoot(shot, location, angle_shift, color_shift):
	var shot_instance = shot.instantiate()
	add_child(shot_instance)
	shot_instance.position = location
	shot_instance.rotation += deg_to_rad(angle_shift)
	shot_instance.modulate = color_shift
	play_audio_player_shot.emit()

func _on_label_timer_timeout():
	if $UI/ScreenLabel.visible:
		$UI/ScreenLabel.visible = false
	else:
		$UI/ScreenLabel.visible = true

func _on_enemies_enemy_score(enemy_score):
	score_change(enemy_score)
	
func _on_enemies_all_enemies_defeated():
	stop_game()
	$UI/ScreenLabel.text = TEXT_CONGRATULATIONS
	$UI/ScreenLabel/SubLabel.text = TEXT_CONTINUE
	$UI/LabelTimer.start()
	play_audio_stage_clear.emit()

func _on_player_lives_change(lives):
	if lives == 0:
		game_over()

func _on_top_margin_area_entered(area):
	score_change(SCORE_MISS)
	
func save_score():
	# decide on on new high scores
	high_scores.append(str(current_score))
	high_scores.sort_custom(func(a, b): return a.naturalnocasecmp_to(b) > 0)
	
	# save new high scores to file
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	for s in min(high_scores.size(), 3):
		save_file.store_line(str(high_scores[s]))
		# display high score
		
	save_file.close()
	
	load_high_scores()
	
func load_high_scores():
	high_scores.clear()
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file == null:
		return
		
	while save_file.get_position() < save_file.get_length():
		#score_aux = int(save_file.get_line())
		high_scores.append(save_file.get_line())
	save_file.close()
	
func show_high_scores():
	var hscore_text = TEXT_HIGH_SCORES
	for s in high_scores:
		hscore_text += s + "\n"
	$UI/HighScoresLabel.text = hscore_text
	$UI/HighScoresLabel.visible = true
