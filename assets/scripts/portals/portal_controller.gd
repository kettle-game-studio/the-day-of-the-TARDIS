extends Node
class_name PortalController

@export var player_camera: Camera3D
@export var remote_camera: Camera3D
@export var remote_viewport: SubViewport
@export var room1_base: Node3D
@export var room2_base: Node3D
@export var portal_home: Node3D

@export var player: Node3D
@export var portal: Node3D

enum RoomState { ROOM1, ROOM2 }
enum PortalState { ENABLED, DISABLED }

var room_state = RoomState.ROOM1
var portal_state = PortalState.DISABLED

func _ready():
	disable_portal()

func _process(delta):
	if portal_state != PortalState.ENABLED:
		return

	var shift = room2_base.global_position - room1_base.global_position
	if room_state == RoomState.ROOM1:
		shift = -shift
	remote_camera.global_position = player_camera.global_position + _get_room_shift()
	remote_camera.global_rotation = player_camera.global_rotation
	remote_camera.near = player.position.distance_to(portal.position)

# translate from corrent room to remote room
func _get_room_shift():
	var shift = room2_base.global_position - room1_base.global_position
	if room_state == RoomState.ROOM2:
		shift = -shift
	return shift

func enable_portal(position: Vector3, rotation: Vector3):
	portal_state = PortalState.ENABLED
	portal.global_rotation.y = rotation.y
	portal.global_position = position
	remote_viewport.disable_3d = false

func disable_portal():
	portal_state = PortalState.DISABLED
	portal.global_position = portal_home.global_position

func switch_room(body: Area3D):
	var portal_normal = portal.transform.basis.z
	var portal_to_body = (body.global_position - portal.global_position).normalized()
	var dot_product = portal_normal.dot(portal_to_body)
	if dot_product > 0:
		portal_normal=-1*portal_normal
	if body is BulletContoller:
		var body_forward = body.get_move_direction()
		var angle_cos = portal_normal.dot(body_forward)
		body.global_position += _get_room_shift()+body_forward*0.2
		return
	player.global_position += _get_room_shift()+0.2*portal_normal
	if portal_state == PortalState.ENABLED:
		portal.global_position += _get_room_shift()

	if room_state == RoomState.ROOM1:
		room_state = RoomState.ROOM2
	elif room_state == RoomState.ROOM2:
		room_state = RoomState.ROOM1
	_process(0)
