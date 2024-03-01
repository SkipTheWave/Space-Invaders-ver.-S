extends Label

const TEXT_START = "LIVES:"
const START_LIVES = 3

# Called when the node enters the scene tree for the first time.
func _ready():
	change_text(START_LIVES)

func _on_player_lives_change(lives):
	change_text(lives)
	
func change_text(hearts):
	text = TEXT_START
	for i in hearts:
		text += "♡"
