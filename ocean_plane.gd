extends MeshInstance3D

# The 5.0 comes from the plane size and the 600.0 comes from the texture scale
# The .32 comes from the size in pixels of the texture itself
const SCROLL_FACTOR = .32 * 5.0 / 600.0
const AMBIENT_SCROLL = Vector2(-1.7, -0.6)

var scroll = Vector2.ZERO

func add_scroll(scrollAdd):
	scroll += scrollAdd


func _process(delta):
	scroll += AMBIENT_SCROLL * delta
	get_surface_override_material(0).set_shader_parameter("scroll", scroll * SCROLL_FACTOR)
