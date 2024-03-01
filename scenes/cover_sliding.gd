extends Cover

const SPEED_ABS = 20.0
const MARGIN = 40.0
var speed = SPEED_ABS

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if position.x <= MARGIN:
		speed = SPEED_ABS
	elif position.x >= get_viewport_rect().size.x - MARGIN:
		speed = -SPEED_ABS
	
	position.x += speed * delta
	
