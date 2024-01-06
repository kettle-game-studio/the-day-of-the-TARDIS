extends CharacterBody3D
class_name Dalek

signal killed(dalek: Dalek, by: BulletContoller)
signal died(dalek: Dalek, corpse: DalekCorpse, by: BulletContoller)

@export var dalek_id: int = 0
@export var corpse_prefab: PackedScene
@export var patrol_path: Path3D
@export_range(0., 1.) var start_patrol_from = 0.0
@export_category("Move and perception")
@export var move_speed = 1.0
@export var max_move_speed = 5.0
@export var view_angle = 120
@export var head_speed = 200
@export var gun_speed = 90
@export var rotation_speed = 90

enum State {PATROL, ATTAK}
var state = State.PATROL

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_direction = Vector2(0,0)
# Initialized outiside by parent
var timezone: Timezone = null

@onready var gun: Gun = $Dalek2/Armature/Skeleton3D/LeftArmBone/Gun
@onready var head_bone: BoneAttachment3D = $Dalek2/Armature/Skeleton3D/HeadBone
@onready var eye_bone: BoneAttachment3D = $Dalek2/Armature/Skeleton3D/EyeBone
@onready var left_arm_bone: BoneAttachment3D = $Dalek2/Armature/Skeleton3D/LeftArmBone
@onready var right_arm_bone: BoneAttachment3D = $Dalek2/Armature/Skeleton3D/RightArmBone
@onready var skeleton = $Dalek2/Armature/Skeleton3D

# distanse, meters
var last_offset = 0.0

func _ready():
	assert(dalek_id != 0, "DALEK WITH DEFAULT ID")
	gun.scene = get_parent_node_3d()
	gun.ignore_bodies[self] = true
	if patrol_path:
		last_offset = start_patrol_from*patrol_path.curve.get_baked_length()
		global_transform = patrol_path.global_transform * patrol_path.curve.sample_baked_with_rotation(last_offset)

func _process(delta):
	#return
	var bone = head_bone	
	var head_rotation = head_angle_to_player(bone, "x")
	
	var gun_bone = left_arm_bone
	if head_rotation == null || abs(head_rotation) > deg_to_rad(view_angle):
		state = State.PATROL
		rotate_with_speed(bone, 0, deg_to_rad(head_speed)*delta)
		rotate_with_speed(gun_bone, 0, deg_to_rad(gun_speed)*delta)
		return
	state = State.ATTAK
	var body_rotation = head_angle_to_player(self, "z")
	if body_rotation != null:
		rotate_with_speed(self, body_rotation, deg_to_rad(rotation_speed)*delta)
	rotate_with_speed(bone, head_rotation, deg_to_rad(head_speed)*delta)
	var gun_rotation = head_angle_to_player(gun_bone, "y")
	if gun_rotation == null:
		return
	var clumped = clamp(gun_rotation, -PI/4, PI/4)
	rotate_with_speed(gun_bone, clumped, deg_to_rad(gun_speed)*delta)
	if clumped == gun_rotation:
		gun.fire()

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
	if not is_on_floor():
		velocity.y -= gravity * delta

	if state == State.ATTAK || patrol_path == null:
		return
	var target_offset = move_speed*timezone.level.clock+(start_patrol_from*patrol_path.curve.get_baked_length())
	var move_speed = min(max_move_speed, max(0, target_offset-last_offset))
	#print_debug(dalek_id, " ", last_offset, " ", patrol_path.curve.get_baked_length())
	var closest_target_position = patrol_path.global_transform* patrol_path.curve.sample_baked(
			fmod(last_offset+move_speed, patrol_path.curve.get_baked_length())
		)
	var to_closest_target = closest_target_position - global_position
	var direction = Vector3(to_closest_target.x, 0, to_closest_target.z).normalized()
	var angle = look_dir_angle(self, direction)
	rotate_with_speed(self, angle, deg_to_rad(rotation_speed)*delta)
	print_debug(dalek_id, " ", angle)
	#move_speed*=max(1., 1./(abs(2*angle)*abs(2*angle)))
	var speed = move_speed
	if abs(rotation.y - angle) > PI/10:
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
	killed.emit(self, bullet)
	die(bullet)
	pass

func die(reason = null):
	var corpse = corpse_prefab.instantiate() as DalekCorpse
	get_parent().add_child(corpse)
	corpse.dalek_id = dalek_id
	corpse.global_transform = global_transform	
	died.emit(self, corpse, reason)
	get_parent().call_deferred("remove_child", self)
	
