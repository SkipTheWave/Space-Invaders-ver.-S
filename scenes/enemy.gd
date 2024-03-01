extends Area2D
class_name Enemy

signal enemy_death(pos, score)
signal player_damage
signal shoot_signal(shot_instance)

const DEATH_ANIM_FRAME = 2

@export var score = 0
@export var shot_speed_mod = 1.0
@export var shot_color : Color
var dead = false

func _ready():
	add_to_group("enemy")

func move(direction, speed):
	if not dead:
		position += direction * speed
		var sprite = $AnimatedSprite2D
		if sprite.frame == 1:
			sprite.frame = 0
		elif sprite.frame == 0:
			sprite.frame = 1
		
func is_unobstructed():
	return !$RayCast2D.is_colliding()
	
func kill():
	$DeathTimer.start()
	$AnimatedSprite2D.frame = DEATH_ANIM_FRAME
	$CollisionShape2D.set_deferred("disabled", true)
	dead = true
	enemy_death.emit(position, score, shot_color)

func _on_area_entered(area):
	if area.is_in_group("player_shot"):
		kill()	
		area.queue_free()

func _on_death_timer_timeout():
	queue_free()

