extends CharacterBody3D
class_name PlayerController

enum State {PLAY, DIALOG, INTRO, FULL_BLOCK_DIALOG}

signal killed(reason)

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

@export var settings: GlobalSettings
@export var max_up_rotation_angle = 30
@export var max_down_rotation_angle = 70
@export var portal_controller: PortalController

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera = $CameraPivot
@onready var screwdriver = $CameraPivot/SdriverPivot/Sdriver
@onready var portal_area = $PortalArea

var state = State.INTRO
var mouse_sensivity:
	get:
		return settings.mouse_sensitivity

var can_move:
	get:
		return state == State.PLAY || state == State.INTRO
var has_screwdriver:
	get:
		return state != State.INTRO && state != State.FULL_BLOCK_DIALOG

func _init():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	call_deferred("subscribe")
	
func subscribe():
	portal_controller.change_state.connect(_on_portal_changed)

func _on_portal_changed(state: PortalController.PortalState):
	if state == PortalController.PortalState.ENABLED:
		screwdriver.open()
	else:
		screwdriver.close()		

func _ready():
	pass

func can_set_portal():
	return !portal_area.has_overlapping_bodies()

func _input(event):
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(event.relative)
	elif Input.is_action_just_pressed("main_action"):
		if !has_screwdriver || !can_set_portal():
			return
		portal_controller.enable_portal(global_position - global_basis.z, global_rotation)
		screwdriver.open()
	elif Input.is_action_just_pressed("second_action"):
	#elif Input.is_action_just_released("main_action"):
		if !has_screwdriver:
			return
		portal_controller.disable_portal()
		screwdriver.close()


func rotate_camera(mouse_shift: Vector2):
	var shift = mouse_shift * mouse_sensivity/1000
	rotate_y(-shift.x)
	camera.rotation.x = clamp(camera.rotation.x - shift.y, -deg_to_rad(max_down_rotation_angle), deg_to_rad(max_up_rotation_angle))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	if !can_move:
		return

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if (portal_controller.portal_state == portal_controller.PortalState.DISABLED):
		if (!can_set_portal()):
			screwdriver.warning()
		else:
			screwdriver.normal()

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
	screwdriver.shake_speed = velocity.length()
		
	move_and_slide()

func _on_bullet(bullet: BulletContoller):
	killed.emit(bullet)
