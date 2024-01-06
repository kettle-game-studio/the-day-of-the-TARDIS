@tool
extends MeshInstance3D

@export var dalek: Dalek
@export var draw: bool
@export var label: Label
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func draw_line(from: Vector3, to: Vector3, up: Vector3 = Vector3(0, 0, 1)):
	from-=global_position
	to-=global_position
	var dir = to-from
	var normal = dir.cross(up).normalized()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	mesh.surface_set_normal(up)
	mesh.surface_set_uv(Vector2(0, 0))
	mesh.surface_add_vertex(from-0.1*normal)
	
	mesh.surface_set_normal(up)
	mesh.surface_set_uv(Vector2(0, 1))
	mesh.surface_add_vertex(from+0.1*normal)

	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 1))
	mesh.surface_add_vertex(to+0.1*normal)
	
	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 1))
	mesh.surface_add_vertex(to+0.1*normal)

	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 1))
	mesh.surface_add_vertex(to-0.1*normal)

	mesh.surface_set_normal(up)
	mesh.surface_set_uv(Vector2(0, 0))
	mesh.surface_add_vertex(from-0.1*normal)
	mesh.surface_end()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var dalek_timezone = "Undefiend"
	if 'timezone' in dalek:
		dalek_timezone = Timezone.RoomType.keys()[dalek.timezone.roomType]
	if 'dalek_id' in dalek:
		label.text = "Dalek %d\nTimezone: %s\n" % [dalek.dalek_id, dalek_timezone ]
	mesh.clear_surfaces()
	if !draw:
		return
	draw_line(
		dalek.head_bone.global_position, 
		dalek.head_bone.global_position+dalek.head_bone.global_basis.x)
	# Begin draw.
	
