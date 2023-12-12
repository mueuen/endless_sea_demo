extends Area3D

enum States {PUPPET, IN_PLAY}

const MOVE_VELOCITY = 24.0
const MOVE_ACCEL = 38.0
const MOVE_DECEL = 15.0
const TURN_FACTOR = 2.8

var lateralVelocity = Vector2.ZERO
var yawTarget = 0.0

var inputVector = Vector2.ZERO
var currState = States.IN_PLAY

var swayPhase = 0.0

func set_input_vector(x, y):
	inputVector = Vector2(x, y)


func set_as_puppet():
	currState = States.PUPPET
	inputVector = Vector2.ZERO


func set_as_in_play():
	currState = States.IN_PLAY
	inputVector = Vector2.ZERO


func is_puppet():
	return currState == States.PUPPET


func is_is_play():
	return currState == States.IN_PLAY


func add_angle(angle, add):
	angle += add

	if angle > PI:
		angle -= PI
		angle = -PI + angle
	elif angle <= -PI:
		angle += PI
		angle = PI - angle

	return angle


func approach_angle(to, from, by):
	var shortestDist = angle_shortest_dist(to, from)
	if abs(shortestDist) < abs(by) && signf(shortestDist) == signf(by):
		return add_angle(from, shortestDist)
	else:
		return add_angle(from, by)


func angle_shortest_dist(to, from):
	var baseDist = to - from
	var leftDist = baseDist
	var rightDist = baseDist
	var shortestDist

	if leftDist < 0.0:
		leftDist = 2.0 * PI + leftDist;

	if rightDist > 0.0:
		rightDist = -2.0 * PI + rightDist;

	if abs(rightDist) < leftDist:
		shortestDist = rightDist
	else:
		shortestDist = leftDist

	return shortestDist


func process_in_play(_delta):
	inputVector = Vector2.ZERO

	if Input.is_action_pressed("move_right"):
		inputVector.x = 1.0
	elif Input.is_action_pressed("move_left"):
		inputVector.x = -1.0

	if Input.is_action_pressed("move_up"):
		inputVector.y = 1.0
	elif Input.is_action_pressed("move_down"):
		inputVector.y = -1.0


func _process(delta):
	if currState == States.IN_PLAY:
		process_in_play(delta)

	if inputVector.x != 0.0:
		lateralVelocity.x = move_toward(lateralVelocity.x, MOVE_VELOCITY * sign(inputVector.x), MOVE_ACCEL * delta)
	else:
		lateralVelocity.x = move_toward(lateralVelocity.x, 0.0, MOVE_DECEL * delta)

	if inputVector.y != 0.0:
		lateralVelocity.y = move_toward(lateralVelocity.y, MOVE_VELOCITY * -sign(inputVector.y), MOVE_ACCEL * delta)
	else:
		lateralVelocity.y = move_toward(lateralVelocity.y, 0.0, MOVE_DECEL * delta)

	var lateralSpeed = min(lateralVelocity.length(), MOVE_VELOCITY)
	lateralVelocity = Vector2(lateralSpeed, 0.0).rotated(lateralVelocity.angle())

	position.x += lateralVelocity.x * delta
	position.z += lateralVelocity.y * delta

	if inputVector.x != 0.0 || inputVector.y != 0.0:
		yawTarget = inputVector.angle()

	var turnSpeed = angle_shortest_dist(yawTarget, $boat.rotation.y) * TURN_FACTOR
	$boat.rotation.y = approach_angle(yawTarget, $boat.rotation.y, turnSpeed * delta)

	swayPhase = fmod(swayPhase + delta / 5.0, 1.0)
	$boat.rotation.z = PI / 30.0 * sin(TAU * swayPhase)
