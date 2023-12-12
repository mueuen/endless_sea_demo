extends Node3D

enum States {PRE_FADE, FADING, DONE}

const PRE_FADE_TIME = 0.8
const FADE_TIME = 3.0

var currState = States.PRE_FADE
var timer = PRE_FADE_TIME

func _process(delta):
	timer = move_toward(timer, 0.0, delta)

	match currState:
		States.PRE_FADE:
			if timer == 0.0:
				currState = States.FADING
				timer = FADE_TIME
		States.FADING:
			$screen_tint.modulate.a = timer / FADE_TIME
			if timer == 0.0:
				currState = States.DONE
