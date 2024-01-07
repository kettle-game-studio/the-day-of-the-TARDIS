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
@export var insie_the_tardis: TardisPortal
@export var outsie_the_tardis: TardisPortal

enum PortalState { ENABLED, DISABLED, INSIDE_THE_TARDIS, OUTSIDE_THE_TARDIS }

var player_room = Timezone.RoomType.PRESENT
var portal_state = PortalState.OUTSIDE_THE_TARDIS



func _process(delta):
	if portal_state == PortalState.DISABLED:
		return
	elif portal_state == PortalState.ENABLED:
		remote_camera.global_position = player_camera.global_position + _get_room_shift()
		remote_camera.global_rotation = player_camera.global_rotation

		remote_camera.near = calc_near(portal)
		portal.set_opacity(1.0 - 0.1 * player.global_position.distance_to(portal.global_position))

	elif portal_state == PortalState.INSIDE_THE_TARDIS || portal_state == PortalState.OUTSIDE_THE_TARDIS:
		var current_tardis = insie_the_tardis  if portal_state == PortalState.INSIDE_THE_TARDIS else outsie_the_tardis
		var second_tardis  = outsie_the_tardis if portal_state == PortalState.INSIDE_THE_TARDIS else insie_the_tardis
		var shift = _get_tardis_shift(true)# second_tardis.global_position - current_tardis.global_position

		remote_camera.global_position = player_camera.global_position + shift
		remote_camera.global_rotation = player_camera.global_rotation
		remote_camera.near = calc_near(current_tardis)


# translate from corrent room to remote room
func _get_room_shift():
	var shift = future_base.global_position - present_base.global_position
	if player_room == Timezone.RoomType.FUTURE:
		shift = -shift
	return shift

func _get_tardis_shift(add_offset: bool):
	var current_tardis = insie_the_tardis  if portal_state == PortalState.INSIDE_THE_TARDIS else outsie_the_tardis
	var second_tardis  = outsie_the_tardis if portal_state == PortalState.INSIDE_THE_TARDIS else insie_the_tardis
	var shift = second_tardis.global_position - current_tardis.global_position
	if add_offset:
		shift += 0.7 * second_tardis.global_basis.z
	return shift

func calc_near(target):
	var forward = player_camera.global_basis.z
	var D = forward.dot(target.global_position)
	var near_distance = (forward.dot(player_camera.global_position) - D) / forward.length()
	return max(0.001, abs(near_distance) - 0.5)

func _get_to_future_shift():
	var shift = future_base.global_position - present_base.global_position
	return shift

func enable_portal(position: Vector3, rotation: Vector3):
	if portal_state == PortalState.INSIDE_THE_TARDIS || portal_state == PortalState.OUTSIDE_THE_TARDIS:
		insie_the_tardis.position.z += 10
	portal_state = PortalState.ENABLED
	portal.global_rotation.y = rotation.y
	portal.global_position = position
	portal_shadow.global_rotation.y = rotation.y
	portal_shadow.global_position = position+_get_room_shift()
	remote_viewport.disable_3d = false

func disable_portal():
	if portal_state != PortalState.ENABLED:
		return
	portal_state = PortalState.DISABLED
	portal.global_position = portal_home.global_position
	portal_shadow.global_position = portal_home.global_position

var teleportation_in_progress = {}

func end_teleportation(portal_source: Portal, body: Area3D):
	teleportation_in_progress[body]-=1
	if teleportation_in_progress[body] != 0:
		return
	teleportation_in_progress.erase(body)
	

func switch_tardis():
	if portal_state == PortalState.OUTSIDE_THE_TARDIS:
		player.global_position += _get_tardis_shift(true)
		portal_state = PortalState.INSIDE_THE_TARDIS
	elif portal_state == PortalState.INSIDE_THE_TARDIS:
		player.global_position += _get_tardis_shift(true)
		portal_state = PortalState.OUTSIDE_THE_TARDIS


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
