extends Area2D

const SPEED = 350.0

var angle_shift : float

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var movement = Vector2.from_angle(rotation - PI/2) * SPEED
	position += movement * delta
	
func set_angle_shift(angle):
	angle_shift = angle
	rotation += angle
