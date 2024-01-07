extends Node3D
class_name Gun

@export var bullet_prefab: PackedScene
@export var scene: Node3D
@export var reload_time = 1.
@export var delay_time = 0.2

@onready var bullet_pivot = $BulletPivot
@onready var timer = $Reload
@onready var delay_timer = $Delay
@onready var shoot_audio_stream = $AudioStreamPlayer3D
@onready var scream_audio_stream = $Scream
var can_fire = true
var ignore_bodies: Dictionary = {}
var active_bullets: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func fire():
	if !can_fire:
		return
	can_fire = false
	scream_audio_stream.play(0)
	#delay_timer.start(delay_timer)

func _reload_on_time():
	can_fire = true
	
func immediate_fire():
	shoot_audio_stream.play()
	var bullet = bullet_prefab.instantiate() as BulletContoller
	bullet.ignore_bodies = ignore_bodies
	scene.add_child(bullet)
	bullet.global_position = bullet_pivot.global_position
	bullet.global_rotation = bullet_pivot.global_rotation
	active_bullets[bullet] = bullet
	bullet.tree_exiting.connect(_on_bullet_destroy.bind(bullet))
	timer.start(reload_time)
	

func _on_bullet_destroy(bullet):
	active_bullets.erase(bullet)
	
func restart():
	for bullet in active_bullets:
		bullet.get_parent().call_deferred("remove_child", bullet)
	active_bullets.clear()
	can_fire = true
	timer.stop()
	scream_audio_stream.stop()
	shoot_audio_stream.stop()
	delay_timer.stop()

func cancel():
	scream_audio_stream.stop()
	shoot_audio_stream.stop()
