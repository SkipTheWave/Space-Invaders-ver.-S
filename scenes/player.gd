extends CharacterBody2D

signal shoot(shot, location, angle_shift)
signal lives_change(lives)
signal play_audio_player_hurt

const SPEED = 150.0
const MAX_CHARGE = 5.0
const SHOT_CD_NORMAL = 0.3
const SHOT_CD_UNLEASH = 0.04
const UNLEASH_SHOTS = 40
const UNLEASH_ARC = 10.0

@export var shot_scene : PackedScene
var game_running = false
var START_LIVES = 3
var weapon_charge = 0.0
var lives
var unleash_shots_left = 0
var color_shift : float

func _ready():
	color_shift = 0.0

func _process(delta):
	velocity = Vector2.ZERO
	if game_running:
		if Input.is_action_pressed("move_left"):
			velocity += Vector2.LEFT * SPEED
		if Input.is_action_pressed("move_right"):
			velocity += Vector2.RIGHT * SPEED

		if Input.is_action_just_pressed("shoot"):	
			shoot_func()
		
		# superweapon charge
		if Input.is_action_pressed("shoot"):
			weapon_charge = clampf(weapon_charge + delta, 0.0, MAX_CHARGE)
		else:
			if weapon_charge >= MAX_CHARGE:
				unleash()
				weapon_charge = 0.0
			else:
				weapon_charge = clampf(weapon_charge - delta, 0.0, MAX_CHARGE)

	move_and_collide(velocity * delta)
	
	if unleash_shots_left > 0:
		color_shift = 0.7
	else:
		color_shift = weapon_charge / MAX_CHARGE
	modulate = Color(1.0, 1.0 - color_shift, 1.0 - color_shift)
	
func new_game_reset():
	lives = START_LIVES
	
func take_damage():
	lives -= 1
	lives_change.emit(lives)
	$BlinkTimer.start()
	$InvulnTimer.start()
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
	play_audio_player_hurt.emit()
	
func shoot_func(direction : float = 0.0):
	if $ShotCooldown.is_stopped():
		shoot.emit(shot_scene, position, direction, Color(1.0, 1.0 - color_shift, 1.0 - color_shift))
		$ShotCooldown.start()

func _on_area_2d_area_entered(area):
	if area.is_in_group("enemy") or area.is_in_group("enemy_shot"):
		take_damage()

func _on_invuln_timer_timeout():
	$BlinkTimer.stop()
	$Sprite2D.visible = true
	$Area2D/CollisionShape2D.set_deferred("disabled", false)

func _on_blink_timer_timeout():
	if $Sprite2D.visible:
		$Sprite2D.visible = false
	else:
		$Sprite2D.visible = true
		
func unleash():
	unleash_shots_left = UNLEASH_SHOTS
	$ShotCooldown.start(SHOT_CD_UNLEASH)

func _on_shot_cooldown_timeout():
	if unleash_shots_left > 0:
		unleash_shots_left  -= 2
		shoot_func(randf_range(-UNLEASH_ARC, UNLEASH_ARC) )
		shoot_func(randf_range(-UNLEASH_ARC, UNLEASH_ARC) )
		$ShotCooldown.start()
	else:
		$ShotCooldown.wait_time = SHOT_CD_NORMAL
