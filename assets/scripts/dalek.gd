extends CharacterBody3D
class_name Dalek


@export var SPEED = 1.0
@export var gun: Gun
# Initialized outiside by parent
var timezone: Timezone
@onready var skeleton = $Dalek2/Armature/Skeleton3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var move_direction = Vector2(0,0)

@export_category("Bones")
@export var head_bone: BoneAttachment3D
@export var eye_bone: BoneAttachment3D
@export var left_arm_bone: BoneAttachment3D
@export var right_arm_bone: BoneAttachment3D

func _ready():
	gun.scene = get_parent_node_3d()

func _process(delta):
	var enemy = timezone.level.player;
	var bone = head_bone;
	var eye_dir = bone.global_basis.x;
	var target_dir = (enemy.global_position - bone.global_position)
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(eye_bone.global_position, enemy.global_position)
	query.exclude = [self]
	var cast_result = space_state.intersect_ray(query)
	if !cast_result || !(cast_result.collider is PlayerController):
		bone.rotation.y = 0
		return
	gun.fire()
	bone.rotation.y = atan2(target_dir.x, target_dir.z)
	#left_arm_bone.rotation *= Quaternion.from_euler(Vector3(delta, delta, delta))

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
