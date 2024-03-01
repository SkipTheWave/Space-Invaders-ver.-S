extends Enemy

const UFO_SPEED = 50.0

func _process(delta):
	if not dead:
		position.x -= UFO_SPEED * delta
