extends CharacterBody3D
class_name Dalek

signal killed(dalek: Dalek, by: BulletContoller)
signal died(dalek: Dalek, corpse: DalekCorpse, by: BulletContoller)
@export var colors: Array[Color] = []

@export var dalek_id: int = 0
@export var corpse_prefab: PackedScene
@export var patrol_path: Path3D
@export_range(0., 1.) var start_patrol_from = 0.0
@export_category("Move and perception")
@export var move_speed = 1.0
@export var max_move_speed = 5.0
@export var view_angle = 100
@export var head_speed = 200
@export var gun_speed = 90
@export var rotation_speed = 90
@export var fire_angle_trigger = 3
@export var disappearance_time = PI
enum State {PATROL, ATTAK, DIED}
var state = State.PATROL

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
# Initialized outiside by parent
var timezone: Timezone = null

@onready var gun: Gun = $Dalek2/Armature/Skeleton3D/LeftArmBone/Gun
@onready var head_bone: BoneAttachment3D = $Dalek2/Armature/Skeleton3D/HeadBone
@onready var eye_bone: BoneAttachment3D = $Dalek2/Armature/Skeleton3D/EyeBone
@onready var left_arm_bone: BoneAttachment3D = $Dalek2/Armature/Skeleton3D/LeftArmBone
@onready var right_arm_bone: BoneAttachment3D = $Dalek2/Armature/Skeleton3D/RightArmBone
@onready var skeleton = $Dalek2/Armature/Skeleton3D
@onready var mesh = $Dalek2/Armature/Skeleton3D/Dalek
# distanse, meters
var last_offset = 0.0
var disappearance = 1.0
var color:
	get:
		return colors[dalek_id]

var material: ShaderMaterial
func _ready():
	assert(dalek_id != 0, "DALEK WITH DEFAULT ID")
	gun.scene = get_parent_node_3d()
	gun.ignore_bodies[self] = true
	material = mesh.get_surface_override_material(0) as ShaderMaterial
	material = material.duplicate()
	material.set_shader_parameter("color", color)
	mesh.set_surface_override_material(0, material)
	restart()

func restart():
	state = State.PATROL
	gun.restart()
	disappearance = 1.0
	material.set_shader_parameter("disappearance", 1.0)
	if patrol_path:
		if patrol_path.curve.point_count > 1:
			last_offset = start_patrol_from*patrol_path.curve.get_baked_length()
			global_transform = patrol_path.global_transform * patrol_path.curve.sample_baked_with_rotation(last_offset)
		else:
			last_offset = 0
			global_transform = patrol_path.global_transform

func _process(delta):
	if state == State.DIED:
		die_animation(delta)
		return
	var bone = head_bone	
	var head_rotation = head_angle_to_player(bone, "x")
	
	var gun_bone = left_arm_bone

	if head_rotation == null || abs(head_rotation) > deg_to_rad(view_angle):
		state = State.PATROL
		rotate_with_speed(bone, 0, deg_to_rad(head_speed)*delta)
		rotate_with_speed(gun_bone, 0, deg_to_rad(gun_speed)*delta)
		return
	state = State.ATTAK
	var gun_rotation = head_angle_to_player(gun_bone, "y")
	if gun_rotation != null && abs(gun_rotation) < deg_to_rad(fire_angle_trigger):
		gun.fire()
		return
	#var clumped = clamp(gun_rotation, -PI/4, PI/4)
	#rotate_with_speed(gun_bone, clumped, deg_to_rad(gun_speed)*delta)
	var body_rotation = head_angle_to_player(self, "z")
	if body_rotation != null:
		rotate_with_speed(self, body_rotation, deg_to_rad(rotation_speed)*delta)
	rotate_with_speed(bone, head_rotation, deg_to_rad(head_speed)*delta)

func rotate_with_speed(node: Node3D, angle: float, speed: float):
	node.rotation.y = rotate_toward(node.rotation.y, angle, speed)
func look_dir_angle(node: Node3D, look_dir: Vector3, forward_axis = "z"):
	var angle_to_player = atan2(look_dir.x, look_dir.z)
	var actual_dir = node.global_basis[forward_axis];
	var requred_delta = angle_to_player - atan2(actual_dir.x, actual_dir.z)
	var requred_angle = node.rotation.y + requred_delta
	while requred_angle < -PI:
		requred_angle += 2*PI
	while requred_angle > PI:
		requred_angle -= 2*PI
	return requred_angle
func rotate_to_dir(node: Node3D, look_dir: Vector3, speed: float, forward_axis = "z"):
	rotate_with_speed(node, look_dir_angle(node, look_dir, forward_axis), speed)

func head_angle_to_player(look_bone: Node3D, forward = "z"):
	var bone = look_bone
	var look_dir = where_player(bone, head_bone.global_position.y)
	if look_dir == null:
		return null
	return look_dir_angle(bone, look_dir, forward)

func where_player(look_bone: Node3D, y_raycast: float):
	var enemy = timezone.level.player;
	var enemy_position = enemy.global_position;
	var bone = look_bone;
	var our_position = bone.global_position
	enemy_position.y = y_raycast
	our_position.y = y_raycast
	var look_dir = (enemy_position - our_position)
	
	if timezone.level.player_room == timezone.roomType:
		var cast_result = raycast_enemy(enemy_position-look_dir, enemy_position, true)
		if !cast_result || !(cast_result.collider is PlayerController):
			return null
		return look_dir
		
	var time_shift = timezone.level.portal_controller._get_room_shift()
	look_dir += time_shift
	look_dir.y = 0
	var cast_out_time = raycast_enemy(our_position, our_position+look_dir, true)
	if !cast_out_time || !(cast_out_time.collider is Area3D):
		return null
	var collision_shifted = cast_out_time.position-time_shift
	var cast_player_time = raycast_enemy(
		collision_shifted-0.4*look_dir.normalized(),
		collision_shifted+look_dir, false)
	if !cast_player_time || !(cast_player_time.collider is PlayerController):
		return null
	return look_dir

func raycast_enemy(from: Vector3, to: Vector3, collide_with_areas: bool):#, enemy_timezone: Timezone.RoomType):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collide_with_areas = collide_with_areas
	return space_state.intersect_ray(query)

func _physics_process(delta):
	# Add the gravity.
	if state == State.DIED:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta

	if state == State.ATTAK || patrol_path == null:
		return
	var target_offset = last_offset+move_speed
	if patrol_path.curve.point_count > 1:
		target_offset = move_speed*timezone.level.clock+(start_patrol_from*patrol_path.curve.get_baked_length())
	var speed = min(max_move_speed, max(0, target_offset-last_offset))
	#print_debug(dalek_id, " ", last_offset, " ", patrol_path.curve.get_baked_length())
	var closest_target_position = patrol_path.global_position
	if patrol_path.curve.point_count > 1:
		closest_target_position = patrol_path.global_transform* patrol_path.curve.sample_baked(
			fmod(last_offset+move_speed, patrol_path.curve.get_baked_length())
		)
	var to_closest_target = closest_target_position - global_position
	var direction = Vector3(to_closest_target.x, 0, to_closest_target.z).normalized()
	if patrol_path.curve.point_count <= 1 && to_closest_target.length() < 0.4:
		direction = patrol_path.global_basis.z.normalized()
		var angle = look_dir_angle(self, direction)
		rotate_with_speed(self, angle, deg_to_rad(rotation_speed)*delta)
		move_and_slide()
		return
	var angle = look_dir_angle(self, direction)
	rotate_with_speed(self, angle, deg_to_rad(rotation_speed)*delta)
	#move_speed*=max(1., 1./(abs(2*angle)*abs(2*angle)))
	if abs(rotation.y - angle) > PI/4:
		speed = 0.1
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	move_and_slide()
	last_offset += speed*delta

func _on_bullet(bullet):
	if state == State.DIED:
		return
	killed.emit(self, bullet)
	die(bullet)

func die(reason = null, where: Transform3D = global_transform):
	if state == State.DIED:
		return
	state = State.DIED
	gun.cancel()
	var corpse = corpse_prefab.instantiate() as DalekCorpse
	corpse.dalek_id = dalek_id
	corpse.killed = reason != null
	corpse.color = color
	corpse.disappearance_time = disappearance_time
	get_parent().add_child(corpse)
	corpse.global_transform = where
	died.emit(self, corpse, reason)
	if reason != null:
		disappearance = 0.0
		global_position = timezone.level.dalek_home.global_position

func die_animation(delta: float):
	if disappearance > 0.0:
		disappearance-=delta/disappearance_time
		material.set_shader_parameter("disappearance", max(0.0, disappearance))
		if disappearance <= 0.0:
			global_position = timezone.level.dalek_home.global_position	
