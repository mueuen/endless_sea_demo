extends Camera3D

@export var lookTarget : Node3D = null

func _process(_delta):
	look_at(lookTarget.position)
