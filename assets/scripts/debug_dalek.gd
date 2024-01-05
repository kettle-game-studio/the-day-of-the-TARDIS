@tool
extends MeshInstance3D

@export var dalek: Dalek
@export var draw: bool
@export var label: Label
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func draw_line(from: Vector3, to: Vector3):
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 0))
	mesh.surface_add_vertex(from)

	mesh.surface_set_normal(Vector3(0, 0, 1))
	mesh.surface_set_uv(Vector2(0, 1))
	mesh.surface_add_vertex(to)

	mesh.surface_end()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !draw:
		return
	if 'timezone' in dalek:
		label.text = Timezone.RoomType.keys()[dalek.timezone.roomType] + "\nPlayer: " + Timezone.RoomType.keys()[dalek.timezone.level.player_room]
	mesh.clear_surfaces()
	
	draw_line(
		dalek.head_bone.global_position, 
		dalek.head_bone.global_position+dalek.head_bone.global_basis.x)
	# Begin draw.
	
