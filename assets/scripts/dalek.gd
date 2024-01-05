extends CharacterBody3D
class_name Dalek

signal killed(dalek: Dalek, by: BulletContoller)
signal died(dalek: Dalek, corpse: DalekCorpse, by: BulletContoller)

@export var SPEED = 1.0
@export var dalek_id: int = 0
@export var corpse_prefab: PackedScene
@export var view_angle = 100

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

func _ready():
	gun.scene = get_parent_node_3d()
	gun.ignore_bodies[self] = true
	assert(dalek_id != 0, "DALEK WITH DEFAULT ID")

func _process(delta):
	var bone = head_bone	
	var requred_angle = head_angle_to_player(bone)
	if requred_angle == null || abs(requred_angle) / PI * 180 > view_angle:
		bone.rotation.y = 0
		return
	bone.rotation.y = requred_angle
	var gun_bone = left_arm_bone
	var gun_rotation = head_angle_to_player(gun_bone, "y")
	if gun_rotation == null:
		return
	var clumped = clamp(gun_rotation, -PI/4, PI/4)
	gun_bone.rotation.y = clumped
	if clumped == gun_rotation:
		gun.fire()

func head_angle_to_player(look_bone: Node3D, forward = "x"):
	var bone = look_bone
	var look_dir = where_player(bone)
	if look_dir == null:
		return null
	var angle_to_player = atan2(look_dir.x, look_dir.z)
	var actual_dir = bone.global_basis[forward];
	var requred_delta = angle_to_player - atan2(actual_dir.x, actual_dir.z)
	var requred_angle = bone.rotation.y + requred_delta
	while requred_angle < -PI:
		requred_angle += 2*PI
	while requred_angle > PI:
		requred_angle -= 2*PI
	return requred_angle

func where_player(look_bone: Node3D):
	var enemy = timezone.level.player;
	var enemy_position = enemy.global_position;
	var bone = look_bone;
	var our_position = bone.global_position
	enemy_position.y = our_position.y
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

	var direction = (transform.basis * Vector3(move_direction.x, 0, move_direction.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

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
	
