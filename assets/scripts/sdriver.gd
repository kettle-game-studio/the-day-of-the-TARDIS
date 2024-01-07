extends Node3D
class_name SDriver

@onready var animator = $AnimationPlayer
@onready var mesh = $Armature/Skeleton3D/SDriver
@onready var screwdriver_audiostream = $Screwdriver

var opened = false
var open_time = 0.1
var material: StandardMaterial3D
func open():
	if opened == true:
		return
	screwdriver_audiostream.play(2)
	animator.play("ArmatureAction", -1, 1/open_time)
	opened = true

func close():
	if opened == false:
		return
	animator.play("ArmatureAction", -1, -1/open_time, true)
	opened = false

func warning():
	var a = animator.current_animation_length
	var b = animator.current_animation_position
	var c = animator.movie_quit_on_finish
	var d = animator.current_animation
	if animator.current_animation != "ArmatureAction":
		animator.play("Warning", -1, 1)

func normal():
	if animator.current_animation != "ArmatureAction":
		animator.play("RESET", -1, 1)

# Called when the node enters the scene tree for the first time.
var initial_rotation
func _ready():
	initial_rotation = rotation
	material = mesh.get_active_material(0) as StandardMaterial3D
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
var time = 0
var shake_speed = 0
func _process(delta):
	time+=delta*(shake_speed+1.)
	get_parent_node_3d().rotation.y = sin(time)/15.
	get_parent_node_3d().rotation.z = sin(time*0.9)/30.
	#rotation.y = initial_rotation.y + sin(time)/2-0.5
	rotation.x = initial_rotation.x + sin(time*0.9)/2-0.5
