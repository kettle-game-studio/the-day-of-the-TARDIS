extends Node
class_name PortalController

@export var player_camera: Camera3D
@export var remote_camera: Camera3D
@export var remote_viewport: SubViewport
@export var present_base: Node3D
@export var future_base: Node3D
@export var portal_home: Node3D

@export var player: Node3D
@export var portal: Portal
@export var portal_shadow: Portal

enum PortalState { ENABLED, DISABLED }

var player_room = Timezone.RoomType.PRESENT
var portal_state = PortalState.DISABLED

func _ready():
	disable_portal()

func _process(delta):
	if portal_state != PortalState.ENABLED:
		return

	remote_camera.global_position = player_camera.global_position + _get_room_shift()
	remote_camera.global_rotation = player_camera.global_rotation
	remote_camera.near = player.position.distance_to(portal.position)

# translate from corrent room to remote room
func _get_room_shift():
	var shift = future_base.global_position - present_base.global_position
	if player_room == Timezone.RoomType.FUTURE:
		shift = -shift
	return shift

func enable_portal(position: Vector3, rotation: Vector3):
	portal_state = PortalState.ENABLED
	portal.global_rotation.y = rotation.y
	portal.global_position = position
	portal_shadow.global_rotation.y = rotation.y
	portal_shadow.global_position = position+_get_room_shift()
	remote_viewport.disable_3d = false

func disable_portal():
	portal_state = PortalState.DISABLED
	portal.global_position = portal_home.global_position
	portal_shadow.global_position = portal_home.global_position

var teleportation_in_progress = {}

func end_teleportation(portal_source: Portal, body: Area3D):
	teleportation_in_progress[body]-=1
	if teleportation_in_progress[body] != 0:
		return
	teleportation_in_progress.erase(body)
	

func switch_room(portal_source: Portal, body: Area3D):
	if teleportation_in_progress.has(body):
		teleportation_in_progress[body]+=1
		return
	teleportation_in_progress[body] = 1
	var portal_normal = portal_source.transform.basis.z
	var portal_to_body = (body.global_position - portal_source.global_position).normalized()
	var dot_product = portal_normal.dot(portal_to_body)
	if dot_product > 0:
		portal_normal=-1*portal_normal
	if body is BulletContoller:
		var body_forward = body.get_move_direction()
		var angle_cos = portal_normal.dot(body_forward)
		body.global_position += portal_source.shift_sign*_get_room_shift()
		return
	player.global_position += _get_room_shift()+0.2*portal_normal
	if portal_state == PortalState.ENABLED:
		portal_shadow.global_position = portal.global_position
		portal.global_position += _get_room_shift()

	if player_room == Timezone.RoomType.PRESENT:
		player_room = Timezone.RoomType.FUTURE
	elif player_room == Timezone.RoomType.FUTURE:
		player_room = Timezone.RoomType.PRESENT
	_process(0)


func _on_portal_teleport_attacked(portal):
	disable_portal()
