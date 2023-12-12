extends SpotLight3D

@export var target : Node3D = null

func _process(delta):
	look_at(target.position)
