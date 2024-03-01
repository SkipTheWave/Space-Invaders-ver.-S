extends Area2D
class_name Cover

signal audio_cover_hit

const START_DUR = 10
var durability : int

# Called when the node enters the scene tree for the first time.
func _ready():
	durability = START_DUR


func _on_area_entered(area):
	if area.is_in_group("player_shot") or area.is_in_group("enemy_shot"):
		durability -= 1
		$Sprite2D.modulate.a = durability * (1.0 / START_DUR)
		audio_cover_hit.emit()
		area.queue_free()
		if durability == 0:
			queue_free()
