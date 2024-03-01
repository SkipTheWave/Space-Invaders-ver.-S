extends Label

const TEXT_START = "SCORE:"
const START_SCORE = 0
@export var COLOR_POSITIVE : Color
@export var COLOR_NEGATIVE : Color

# Called when the node enters the scene tree for the first time.
func _ready():
	change_text(0, START_SCORE)
	
func change_text(x, new_score):
	text = TEXT_START + str(new_score)
	var change_label = $ScoreChangeLabel
	change_label.text = ""
	if x == 0:
		return
	elif x > 0:
		change_label.set("theme_override_colors/font_color", COLOR_POSITIVE)
		change_label.text += "+"
	else:
		change_label.set("theme_override_colors/font_color", COLOR_NEGATIVE)
	change_label.text += str(x)
	change_label.visible = true
	$ScoreChangeTimer.start()

func _on_score_change_timer_timeout():
	$ScoreChangeLabel.visible = false

func _on_main_score_change_signal(x, new_score):
	change_text(x, new_score)
