extends Node3D

const WARP_IN_SOUND = preload("res://warp_in.wav")
const WARP_OUT_SOUND = preload("res://warp_out.wav")
const WARP_IN_HI_SOUND = preload("res://warp_in_hi.wav")
const WARP_OUT_HI_SOUND = preload("res://warp_out_hi.wav")
const WARP_IN_LO_SOUND = preload("res://warp_in_lo.wav")
const WARP_OUT_LO_SOUND = preload("res://warp_out_lo.wav")

const BOUNDS_SIZE = Vector2(120.0, 80.0)
const POST_WARP_TIME = 0.8

const CLOSEST_Z = 18.0
const FARTHEST_Z = -251.0
const Z_RANGE = abs(FARTHEST_Z - CLOSEST_Z)

const CLOSEST_X = 97.0
const FARTHEST_X = 240.0
const X_RANGE = FARTHEST_X - CLOSEST_X

const EASTER_EGG_THRESHOLD = 4


enum {WARP_IN, WARP_IN_HI, WARP_IN_LO, WARP_OUT, WARP_OUT_HI, WARP_OUT_LO}
const WARP_SOUNDS = {
	WARP_IN : WARP_IN_SOUND,
	WARP_OUT : WARP_OUT_SOUND,
	
	WARP_IN_HI : WARP_IN_HI_SOUND,
	WARP_OUT_HI : WARP_OUT_HI_SOUND,

	WARP_IN_LO : WARP_IN_LO_SOUND,
	WARP_OUT_LO : WARP_OUT_LO_SOUND
}

enum WarpTriggers {UP, RIGHT, LEFT, DOWN, NONE}
const WARP_TRIGGERS = {
	WarpTriggers.UP : -270.0,
	WarpTriggers.RIGHT : CLOSEST_X,
	WarpTriggers.LEFT : -CLOSEST_X,
	WarpTriggers.DOWN : 22.0,
}
enum WarpState {OFF, WAITING, REAPPEARING}
@onready var WARP_SNDPLAYERS = {
	WarpTriggers.UP : $up_warp_sound,
	WarpTriggers.DOWN : $down_warp_sound,
	WarpTriggers.RIGHT : $right_warp_sound,
	WarpTriggers.LEFT : $left_warp_sound
}

@export var shoutout : Node3D = null
@export var oceanPlane : Node3D = null
@export var player : Node3D = null
@export var lookTarget : Node3D = null

var oceanPlaneOffset = 0.0
var atXBound = false
var atZBound = false
var upWarpStreak = 0
var playedShoutoutSound = false

var currWarpState = WarpState.OFF
var warpTaken = WarpTriggers.NONE
var postWarpTimer = 0.0
var warpReappearTimer = 0.0
# Account for perspective on x axis warps
var playerZRatio = 0.0
var warpXAdd = 0.0

func play_warp_sound(direction, type):
	var warpSound = WARP_SOUNDS[type]
	var sndPlayer = WARP_SNDPLAYERS[direction]
	sndPlayer.stop()
	sndPlayer.stream = warpSound
	sndPlayer.play()


func cos_interp(a):
	return 1.0 - (cos(PI * a) + 1.0) * 0.5


func process_warp_cutscene(delta):
	match currWarpState:
		WarpState.OFF:
			var advanceState = false
			var xDist = player.position.x - position.x
			var zDist = player.position.z - position.z
			playerZRatio = min(abs(zDist - 18.0) / Z_RANGE, 1.0)
			warpXAdd = X_RANGE * playerZRatio

			if xDist > 0.0 && xDist > WARP_TRIGGERS[WarpTriggers.RIGHT] + warpXAdd:
				player.set_as_puppet()
				warpTaken = WarpTriggers.RIGHT
				play_warp_sound(WarpTriggers.RIGHT, WARP_OUT)
				advanceState = true
			elif xDist < 0.0 && xDist < WARP_TRIGGERS[WarpTriggers.LEFT] - warpXAdd:
				warpTaken = WarpTriggers.LEFT
				player.set_as_puppet()
				play_warp_sound(WarpTriggers.LEFT, WARP_OUT)
				advanceState = true
			elif zDist > 0.0 && zDist > WARP_TRIGGERS[WarpTriggers.DOWN]:
				warpTaken = WarpTriggers.DOWN
				player.set_as_puppet()
				play_warp_sound(WarpTriggers.DOWN, WARP_OUT_LO)
				advanceState = true
			elif zDist < 0.0 && zDist < WARP_TRIGGERS[WarpTriggers.UP]:
				warpTaken = WarpTriggers.UP
				player.set_as_puppet()
				play_warp_sound(WarpTriggers.UP, WARP_OUT_HI)
				advanceState = true

			if advanceState:
				postWarpTimer = POST_WARP_TIME
				currWarpState = WarpState.WAITING

		WarpState.WAITING:
			postWarpTimer = move_toward(postWarpTimer, 0.0, delta)
			if postWarpTimer == 0.0:
				match warpTaken:
					WarpTriggers.RIGHT:
						player.position.x = -BOUNDS_SIZE.x + WARP_TRIGGERS[WarpTriggers.LEFT] - warpXAdd
						position.x = -BOUNDS_SIZE.x
						player.set_input_vector(1.0, 0.0)
						warpReappearTimer = 3.0 + 3.8 * playerZRatio
						play_warp_sound(WarpTriggers.LEFT, WARP_IN)
					WarpTriggers.LEFT:
						player.position.x = BOUNDS_SIZE.x + WARP_TRIGGERS[WarpTriggers.RIGHT] + warpXAdd
						position.x = BOUNDS_SIZE.x
						player.set_input_vector(-1.0, 0.0)
						warpReappearTimer = 3.0 + 3.8 * playerZRatio
						play_warp_sound(WarpTriggers.RIGHT, WARP_IN)
					WarpTriggers.DOWN:
						player.position.z = -BOUNDS_SIZE.y + WARP_TRIGGERS[WarpTriggers.UP]
						position.z = -BOUNDS_SIZE.y
						player.set_input_vector(0.0, -1.0)
						warpReappearTimer = 6.0
						play_warp_sound(WarpTriggers.UP, WARP_IN_HI)
					WarpTriggers.UP:
						player.position.z = BOUNDS_SIZE.y + WARP_TRIGGERS[WarpTriggers.DOWN]
						position.z = BOUNDS_SIZE.y
						player.set_input_vector(0.0, 1.0)
						warpReappearTimer = 2.0
						play_warp_sound(WarpTriggers.DOWN, WARP_IN_LO)
				currWarpState = WarpState.REAPPEARING

		WarpState.REAPPEARING:
			warpReappearTimer = move_toward(warpReappearTimer, 0.0, delta)
			if warpReappearTimer == 0.0:
				if warpTaken == WarpTriggers.UP:
					upWarpStreak = upWarpStreak + 1
					if upWarpStreak == EASTER_EGG_THRESHOLD:
						$good_job_sound.play()
						shoutout.show()
					elif upWarpStreak == EASTER_EGG_THRESHOLD + 1:
						shoutout.hide()
						upWarpStreak = 1
				else:
					upWarpStreak = 0
					shoutout.hide()
				playedShoutoutSound = false

				player.set_as_in_play()
				currWarpState = WarpState.OFF


func _process(delta):
	var newPosition = player.position + Vector3(0.0, 80.0, 55.0)

	if abs(newPosition.x) > BOUNDS_SIZE.x - 15.0:
		atXBound = true
		var bound = BOUNDS_SIZE.x * sign(newPosition.x)
		newPosition.x = position.x + (bound - position.x) * 2.0 * delta
	elif atXBound:
		var intermPos = newPosition
		var posAdd = (newPosition.x - position.x) * 6.0
		posAdd = clamp(posAdd, 20.0 * sign(posAdd), posAdd)
		intermPos.x = move_toward(position.x, newPosition.x, abs(posAdd) * delta)
		if is_equal_approx(intermPos.x, newPosition.x):
			atXBound = false
		newPosition = intermPos

	if abs(newPosition.z) > BOUNDS_SIZE.y - 15.0:
		atZBound = true
		var bound = BOUNDS_SIZE.y * sign(newPosition.z)
		newPosition.z = position.z + (bound - position.z) * 2.0 * delta
	elif atZBound:
		var intermPos = newPosition
		var posAdd = (newPosition.z - position.z) * 6.0
		posAdd = clamp(posAdd, 20.0 * sign(posAdd), posAdd)
		intermPos.z = move_toward(position.z, newPosition.z, abs(posAdd) * delta)
		if is_equal_approx(intermPos.z, newPosition.z):
			atZBound = false
		newPosition = intermPos

	var velocity = newPosition - position
	position = newPosition

	process_warp_cutscene(delta)
	if !playedShoutoutSound && upWarpStreak == EASTER_EGG_THRESHOLD:
		var lateralDist = sqrt((shoutout.position.x - position.x) ** 2.0 + (shoutout.position.z - position.z) ** 2.0)
		if lateralDist < 45.0:
			$shoutout_sound.play()
			playedShoutoutSound = true

	# ---

	lookTarget.position = position - Vector3(0.0, 80.0, 55.0)

	oceanPlane.position.z = -55.0
	oceanPlane.position.y = -80.0
	oceanPlane.add_scroll(Vector2(velocity.x, velocity.z))
