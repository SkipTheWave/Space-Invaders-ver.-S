extends Node

signal all_enemies_defeated()
signal enemy_score(score)

signal play_audio_enemy_death
signal play_audio_enemy_shot

const MOVE_SPEED = 6.0
const NUM_ENEMY_ROWS = 5
const NUM_ENEMIES_PER_ROW = 9
const ENEMY_TOP_MARGIN = 30
const ENEMY_LEFT_MARGIN = 15
const MOVE_TIMER_MIN_TIME = 0.01
const SHOOT_TIMER_TIME = 2.0

@onready var enemy_shot_scene = preload("res://scenes/enemy_shot.tscn")
@onready var explosion_scene = preload("res://scenes/explosion.tscn")

@export var enemy_scenes = []
var enemies : Array[Array]
var num_enemies = 0
var current_state : EnemyState
var queued_state : EnemyState
var states : Dictionary = {}
var current_row
var timer_next_time : float

var current_stage : int

const STATE_RIGHT = "StateMoveRight"
const STATE_LEFT = "StateMoveLeft"
const STATE_DOWN = "StateMoveDown"

const UFO_MIN_TIMER = 10.0
const UFO_MAX_TIMER = 30.0
const UFO_START_POS = Vector2(244.0, 35.0)
@onready var ufo_scene = preload("res://scenes/enemy_ufo.tscn")
var ufo_counter

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in get_children():
		if child is EnemyState:
			states[child.name.to_lower()] = child
			child.transition.connect(on_state_transition)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func reset_enemies():
	enemies.clear()
	get_tree().call_group("enemy", "queue_free")
	current_state = states[STATE_RIGHT.to_lower()]
	queued_state = states[STATE_RIGHT.to_lower()]
	num_enemies = 0
	ufo_counter = 0
	$MoveTimer.stop()
	$ShootTimer.stop()
	$UFOTimer.stop()
	get_tree().call_group("enemy_shot", "queue_free")

func spawn_enemies(window_size):
	reset_enemies()
	$UFOTimer.start(randf_range(UFO_MIN_TIMER, UFO_MAX_TIMER))
	var current_x = ENEMY_LEFT_MARGIN
	var current_y = ENEMY_TOP_MARGIN
	var enemies_per_row = NUM_ENEMIES_PER_ROW + (current_stage / 4)
	var enemy_rows = NUM_ENEMY_ROWS + (current_stage / 3)
	var x_interval = (window_size.x - ENEMY_LEFT_MARGIN - 50) / enemies_per_row
	var y_interval = (window_size.y - ENEMY_TOP_MARGIN - 80) / enemy_rows
	
	for i in enemy_rows:
		enemies.append([])
		# choose random enemy type for each row
		var enemy_type = enemy_scenes[randi_range(0, 2)]
		for j in enemies_per_row:
			var enemy_instance = enemy_type.instantiate()
			enemies[i].append(enemy_instance)
			enemies[i][j] = enemy_instance
			
			# do some setup on new enemy
			enemy_instance.position.x = current_x
			enemy_instance.position.y = current_y
			enemy_instance.enemy_death.connect(on_enemy_death)
			enemy_instance.get_node("RayCast2D").target_position.y = y_interval * 1.5
			
			add_child(enemy_instance)
			current_x += x_interval
			num_enemies += 1

		current_x = ENEMY_LEFT_MARGIN
		current_y += y_interval
	current_row = enemies.size() - 1
	
	calculate_timer()
	$MoveTimer.wait_time = timer_next_time
	
func change_stage(stage):
	current_stage = stage
	$ShootTimer.wait_time = SHOOT_TIMER_TIME * pow(0.92, current_stage)

func on_state_transition(next_state_name):
	queued_state = states[next_state_name.to_lower()]
	
func on_down_state_transition(next_state_name):
	var new_state = states[STATE_DOWN.to_lower()]
	queued_state = new_state	
	new_state.next_state = next_state_name
	

func _on_move_timer_timeout():
	for enemy in enemies[current_row]:
		if is_instance_valid(enemy):
			enemy.move(current_state.direction, MOVE_SPEED + current_stage / 2.0)
		
	current_row -= 1
	
	if current_row < 0:
		# update state and row after all rows have moved
		current_state = queued_state
		if "next_state" in current_state:
			queued_state = states[current_state.next_state.to_lower()]
		else:
			queued_state = current_state
		current_row = enemies.size() - 1
		
	$MoveTimer.start(timer_next_time)
	

func _on_left_margin_area_entered(area):
	if area.is_in_group("enemy") && current_state.name.to_lower() == STATE_LEFT.to_lower():
		on_down_state_transition(STATE_RIGHT)

func _on_right_margin_area_entered(area):
	if area.is_in_group("enemy") && current_state.name.to_lower() == STATE_RIGHT.to_lower():
		on_down_state_transition(STATE_LEFT)

func _on_move_state_down_state_transition(next_state_name):
	on_state_transition(next_state_name)
	
func on_enemy_death(pos, score, explosion_color):
	num_enemies -= 1
	enemy_score.emit(score)
	
	var explosion = explosion_scene.instantiate()
	explosion.position = pos
	explosion.modulate = explosion_color
	add_child(explosion)
	play_audio_enemy_death.emit()
	
	if num_enemies > 0:
		calculate_timer()
	else:
		$MoveTimer.stop()
		$ShootTimer.stop()
		all_enemies_defeated.emit()
		
func calculate_timer():
	timer_next_time = MOVE_TIMER_MIN_TIME + log(num_enemies) / 24

func _on_shoot_timer_timeout():
	var unobstructed_enemies = []
	
	for row in enemies:
		for enemy in row:
			if is_instance_valid(enemy):
				if enemy.is_unobstructed():
					unobstructed_enemies.append(enemy)
	if unobstructed_enemies.size() == 0:
		return

	# shoot
	var shooter = unobstructed_enemies[randi_range(0, unobstructed_enemies.size() - 1)]
	var shot_instance = enemy_shot_scene.instantiate()
	shot_instance.position = shooter.position
	shot_instance.speed *= shooter.shot_speed_mod
	shot_instance.modulate = shooter.shot_color
	get_parent().add_child(shot_instance)
	
	play_audio_enemy_shot.emit()
	
func kill_all_enemies():
	for row in enemies:
		for enemy in row:
			if is_instance_valid(enemy):
				enemy.kill()


func _on_ufo_timer_timeout():
	if ufo_counter >= 2:
		return
	var ufo = ufo_scene.instantiate()
	ufo.position = UFO_START_POS
	ufo.enemy_death.connect(on_ufo_death)
	add_child(ufo)
	ufo_counter += 1
	
func on_ufo_death(pos, score, explosion_color):
	enemy_score.emit(score)
	
	for i in 4:
		var explosion = explosion_scene.instantiate()
		explosion.position = pos
		if i >= 2:
			explosion.modulate = Color(randf_range(0.3, 1.0), randf_range(0.3, 1.0), randf_range(0.3, 1.0))
		else:
			explosion.modulate = explosion_color
		add_child(explosion)
		play_audio_enemy_death.emit()
