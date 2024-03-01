extends Label

const TEXT_START = "STAGE "
const START_STAGE = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	change_text(START_STAGE)
	
func change_text(stage):
	text = TEXT_START + str(stage)


func _on_main_stage_change_signal(stage):
	change_text(stage)
