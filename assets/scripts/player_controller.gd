extends CharacterBody3D
class_name PlayerController

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var mouse_sensivity = 0.75
@export var max_up_rotation_angle = 30
@export var max_down_rotation_angle = 70
@export var portal_controller: PortalController

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $CameraPivot/Camera3D
@onready var screwdriver_audiostream = $Sounds/Screwdriver
@onready var gun = $Gun

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _ready():
	gun.scene = get_parent()

func _input(event):
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.relative)
	elif event is InputEventMouseButton && Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif Input.is_action_just_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif Input.is_action_just_pressed("main_action"):
		portal_controller.enable_portal(global_position - global_basis.z, global_rotation)
		screwdriver_audiostream.play(2)
	elif Input.is_action_just_pressed("second_action"):
		gun.fire()


func rotate_camera(mouse_shift: Vector2):
	var shift = mouse_shift * mouse_sensivity/1000
	rotate_y(-shift.x)
	camera.rotation.x = clamp(camera.rotation.x - shift.y, -deg_to_rad(max_down_rotation_angle), deg_to_rad(max_up_rotation_angle))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var dash = Input.is_action_just_pressed("dash")
	var run = Input.is_action_pressed("dash")
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if dash:
		if velocity.length() < SPEED:
			velocity = transform.basis * Vector3(SPEED, 0, 0)
		velocity.x*=2.5
		velocity.z*=2.5
	elif run:
		velocity.x*=1.5
		velocity.z*=1.5

	move_and_slide()
