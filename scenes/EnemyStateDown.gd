extends EnemyState

var next_state : String
signal state_transition

func trigger_move():
	state_transition.emit(next_state)
	
